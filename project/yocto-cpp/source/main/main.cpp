#include <cstdlib>
#include <cstdio>
#include <atomic>
#include <csignal>
#include <unistd.h>

std::atomic<bool> running(true);

void HandleCancellation(const int arg_signal_number)
{
  static_cast<void>(arg_signal_number);
  running = false;
}

int main(int argc, char** argv)
{
  // Disable stdout buffering
#if (DEBUG == 1)
  setbuf(stdout, NULL);
#endif

  // End endless while-loop with Ctrl+C and call destructors
  std::signal(SIGINT, HandleCancellation);

  while (running)
  {
    printf("Hello world.\n");
    sleep(1U);
  }

  return 0;
}
