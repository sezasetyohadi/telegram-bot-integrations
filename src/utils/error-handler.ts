/**
 * Global error handler for unhandled exceptions and promise rejections
 * This helps prevent the application from crashing when unexpected errors occur
 */

export function setupGlobalErrorHandlers(): void {
  process.on('unhandledRejection', (reason: any, promise: Promise<any>) => {
    console.error('Unhandled Rejection at:', promise);
    console.error('Reason:', reason?.message || String(reason));
    // Application continues running
  });

  process.on('uncaughtException', (error: Error) => {
    console.error('Uncaught Exception:');
    console.error(error.message);
    console.error(error.stack);
    // Application continues running
    // For critical errors, you might want to exit gracefully:
    // process.exit(1);
  });

  console.log('Global error handlers have been set up');
}
