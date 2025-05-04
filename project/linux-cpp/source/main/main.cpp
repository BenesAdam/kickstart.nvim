#include <cstdint>
#include <cstdlib>
#include <cstdio>

int main(int argc, char** argv)
{
  printf("Program name: %s\n", argv[0]);

  const int size = 10;
  for (int i = 0; i < size; ++i)
  {
    for (int j = 0; j < size; ++j)
    {
        printf("#");
    }

    printf("\n");
  }

  return 0;
}

