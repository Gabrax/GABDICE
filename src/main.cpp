// Prevent accidentally selecting integrated GPU
#ifdef __WIN32
extern "C" {
	__declspec(dllexport) unsigned __int32 AmdPowerXpressRequestHighPerformance = 0x1;
	__declspec(dllexport) unsigned __int32 NvOptimusEnablement = 0x1;
}
#endif

#include <iostream>

int main()
{

    std::cout << "compiled\n";
}
