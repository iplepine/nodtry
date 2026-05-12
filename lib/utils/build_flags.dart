class BuildFlags {
  BuildFlags._();

  static const bool storeScreenshotMode = bool.fromEnvironment(
    'STORE_SCREENSHOT_MODE',
  );
}
