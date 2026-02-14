#import <Foundation/Foundation.h>

#import <Squirrel/SQRLDirectoryManager.h>
#import <Squirrel/SQRLShipItLauncher.h>
#import <Squirrel/SQRLShipItRequest.h>

#if __has_include(<ReactiveObjC/ReactiveObjC.h>)
#import <ReactiveObjC/ReactiveObjC.h>
#elif __has_include(<ReactiveCocoa/ReactiveCocoa.h>)
#import <ReactiveCocoa/ReactiveCocoa.h>
#else
#error "ReactiveObjC/ReactiveCocoa headers are required"
#endif

static void PrintUsage(void) {
  fprintf(stderr,
          "Usage: mac_squirrel_agent --staged-app <path> --target-app <path> "
          "--bundle-id <id> [--launch-after-install]\n");
}

static NSString *SafeDescription(NSError *error) {
  if (error == nil) {
    return @"<none>";
  }
  if (error.localizedDescription.length == 0) {
    return [error description];
  }
  return error.localizedDescription;
}

static BOOL WaitSignal(RACSignal *signal, id __autoreleasing *value,
                       NSError **outError) {
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  __block id localValue = nil;
  __block NSError *localError = nil;

  [signal subscribeNext:^(id next) {
    localValue = next;
  }
      error:^(NSError *error) {
        localError = error;
        dispatch_semaphore_signal(sem);
      }
      completed:^{
        dispatch_semaphore_signal(sem);
      }];

  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  if (value != NULL) {
    *value = localValue;
  }
  if (outError != NULL) {
    *outError = localError;
  }
  return localError == nil;
}

static BOOL IsWritableURL(NSURL *url) {
  NSNumber *writable = nil;
  NSError *error = nil;
  BOOL gotValue = [url getResourceValue:&writable forKey:NSURLIsWritableKey error:&error];
  if (!gotValue) {
    return YES;
  }
  return writable.boolValue;
}

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSString *stagedPath = nil;
    NSString *targetPath = nil;
    NSString *bundleId = nil;
    BOOL launchAfterInstall = NO;

    for (int i = 1; i < argc; i++) {
      const char *arg = argv[i];
      if (strcmp(arg, "--staged-app") == 0) {
        if (i + 1 >= argc) {
          PrintUsage();
          return 2;
        }
        stagedPath = [NSString stringWithUTF8String:argv[++i]];
      } else if (strcmp(arg, "--target-app") == 0) {
        if (i + 1 >= argc) {
          PrintUsage();
          return 2;
        }
        targetPath = [NSString stringWithUTF8String:argv[++i]];
      } else if (strcmp(arg, "--bundle-id") == 0) {
        if (i + 1 >= argc) {
          PrintUsage();
          return 2;
        }
        bundleId = [NSString stringWithUTF8String:argv[++i]];
      } else if (strcmp(arg, "--launch-after-install") == 0) {
        launchAfterInstall = YES;
      } else {
        fprintf(stderr, "Unknown argument: %s\n", arg);
        PrintUsage();
        return 2;
      }
    }

    if (stagedPath.length == 0 || targetPath.length == 0 || bundleId.length == 0) {
      PrintUsage();
      return 2;
    }

    NSURL *stagedURL = [NSURL fileURLWithPath:stagedPath];
    NSURL *targetURL = [NSURL fileURLWithPath:targetPath];

    BOOL stagedIsDir = NO;
    BOOL targetExists = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:stagedPath isDirectory:&stagedIsDir] || !stagedIsDir) {
      fprintf(stderr, "staged app does not exist: %s\n", stagedPath.UTF8String);
      return 2;
    }
    targetExists = [[NSFileManager defaultManager] fileExistsAtPath:targetPath];
    if (!targetExists) {
      fprintf(stderr, "target app does not exist: %s\n", targetPath.UTF8String);
      return 2;
    }

    NSError *error = nil;
    NSString *jobLabel = [bundleId stringByAppendingString:@".ShipIt"];
    SQRLDirectoryManager *directoryManager =
        [[SQRLDirectoryManager alloc] initWithApplicationIdentifier:jobLabel];

    id statePathValue = nil;
    if (!WaitSignal([directoryManager shipItStateURL], &statePathValue, &error)) {
      fprintf(stderr, "failed to resolve ShipIt state path: %s\n",
              SafeDescription(error).UTF8String);
      return 1;
    }

    if (![statePathValue isKindOfClass:[NSURL class]]) {
      fprintf(stderr, "invalid ShipIt state path result\n");
      return 1;
    }

    NSURL *stateURL = (NSURL *)statePathValue;
    SQRLShipItRequest *request = [[SQRLShipItRequest alloc]
         initWithUpdateBundleURL:stagedURL
                 targetBundleURL:targetURL
               bundleIdentifier:bundleId
         launchAfterInstallation:launchAfterInstall
             useUpdateBundleName:NO];

    if (request == nil) {
      fprintf(stderr, "failed to build SQRLShipItRequest\n");
      return 1;
    }

    if (!WaitSignal([request writeUsingURL:[RACSignal return:stateURL]], NULL, &error)) {
      fprintf(stderr, "failed to write ShipIt state: %s\n", SafeDescription(error).UTF8String);
      return 1;
    }

    BOOL targetWritable = IsWritableURL(targetURL);
    BOOL parentWritable = IsWritableURL([targetURL URLByDeletingLastPathComponent]);
    BOOL privileged = !targetWritable || !parentWritable;

    if (!WaitSignal([SQRLShipItLauncher launchPrivileged:privileged], NULL, &error)) {
      fprintf(stderr, "failed to launch ShipIt: %s\n", SafeDescription(error).UTF8String);
      return 1;
    }

    printf("ShipIt launch submitted successfully\n");
    return 0;
  }
}
