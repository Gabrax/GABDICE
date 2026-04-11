// Prevent accidentally selecting integrated GPU
#ifdef __WIN32
extern "C" {
	__declspec(dllexport) unsigned __int32 AmdPowerXpressRequestHighPerformance = 0x1;
	__declspec(dllexport) unsigned __int32 NvOptimusEnablement = 0x1;
}
#endif

#include <raylib.h>

#include "physics.h"
#include "dice.h"

int main()
{
    InitWindow(800, 600, "GABDICE");
    SetTargetFPS(60);

    Physics::Init();

    Camera camera = { 0 };
    camera.position = { 0,15,15 };
    camera.target = { 0,0,0 };
    camera.up = { 0,1,0 };
    camera.fovy = 45.0f;
    camera.projection = CAMERA_PERSPECTIVE;

    const Model model = LoadModel("../res/dice.glb");

    Dice dice(model);

    while (!WindowShouldClose())
    {
        const float dt = GetFrameTime();

        Physics::Update(dt);

        BeginDrawing();
        ClearBackground(::RAYWHITE);

        BeginMode3D(camera);

        dice.Draw(dt);

        DrawCube((Vector3){0,-1,0}, 10, 0.5f, 10, ::GRAY);

        EndMode3D();

        DrawFPS(10, 10);
        EndDrawing();
    }

    UnloadModel(model);
    CloseWindow();

    return 0;
}