// Prevent accidentally selecting integrated GPU
#ifdef __WIN32
extern "C" {
	__declspec(dllexport) unsigned __int32 AmdPowerXpressRequestHighPerformance = 0x1;
	__declspec(dllexport) unsigned __int32 NvOptimusEnablement = 0x1;
}
#endif

#include <raylib.h>

#include <Jolt/Jolt.h>
#include <Jolt/RegisterTypes.h>
#include <Jolt/Core/Factory.h>
#include <Jolt/Core/TempAllocator.h>
#include <Jolt/Core/JobSystemThreadPool.h>
#include <Jolt/Physics/PhysicsSystem.h>
#include <Jolt/Physics/Body/BodyCreationSettings.h>
#include <Jolt/Physics/Collision/Shape/BoxShape.h>

using namespace JPH;

namespace Layers {
    static constexpr ObjectLayer NON_MOVING = 0;
    static constexpr ObjectLayer MOVING = 1;
    static constexpr uint NUM_LAYERS = 2;
}

class BroadPhaseLayerInterfaceImpl final : public BroadPhaseLayerInterface {
public:
    BroadPhaseLayerInterfaceImpl() {
        mObjectToBroadPhase[Layers::NON_MOVING] = BroadPhaseLayer(0);
        mObjectToBroadPhase[Layers::MOVING] = BroadPhaseLayer(1);
    }

    [[nodiscard]] uint GetNumBroadPhaseLayers() const override {
        return 2;
    }

    [[nodiscard]] BroadPhaseLayer GetBroadPhaseLayer(ObjectLayer inLayer) const override {
        return mObjectToBroadPhase[inLayer];
    }

#if defined(JPH_EXTERNAL_PROFILE) || defined(JPH_PROFILE_ENABLED)
    const char* GetBroadPhaseLayerName(BroadPhaseLayer inLayer) const override {
        switch (inLayer.GetValue()) {
            case 0: return "NON_MOVING";
            case 1: return "MOVING";
            default: return "UNKNOWN";
        }
    }
#endif

private:
    BroadPhaseLayer mObjectToBroadPhase[Layers::NUM_LAYERS]{};
};

class ObjectLayerPairFilterImpl : public ObjectLayerPairFilter {
public:
    [[nodiscard]] bool ShouldCollide(ObjectLayer inLayer1, ObjectLayer inLayer2) const override {
        return true;
    }
};

class ObjectVsBroadPhaseLayerFilterImpl : public ObjectVsBroadPhaseLayerFilter {
public:
    [[nodiscard]] bool ShouldCollide(ObjectLayer, BroadPhaseLayer) const override {
        return true;
    }
};

int main()
{
    InitWindow(800, 600, "GABDICE");

    Camera camera = { 0 };
    camera.position = { 15,15,15 };
    camera.target = { 0,0,0 };
    camera.up = { 0,1,0 };
    camera.fovy = 45.0f;
    camera.projection = CAMERA_PERSPECTIVE;

    Model model = LoadModel("../res/dice.glb");

    RegisterDefaultAllocator();

    Factory::sInstance = new Factory();
    RegisterTypes();

    PhysicsSystem physics;

    BroadPhaseLayerInterfaceImpl broadPhaseLayerInterface;
    ObjectVsBroadPhaseLayerFilterImpl objectVsBroadPhaseLayerFilter;
    ObjectLayerPairFilterImpl objectLayerPairFilter;

    physics.Init(
        1024, 0, 1024, 1024,
        broadPhaseLayerInterface,
        objectVsBroadPhaseLayerFilter,
        objectLayerPairFilter
    );

    physics.SetGravity(Vec3(0, -9.81f, 0));

    BodyInterface& bodyInterface = physics.GetBodyInterface();

    RefConst<Shape> floorShape = new BoxShape(Vec3(10, 0.5f, 10));

    BodyCreationSettings floorSettings(
        floorShape,
        Vec3(0, -1, 0),
        Quat::sIdentity(),
        EMotionType::Static,
        Layers::NON_MOVING
    );

    Body* floor = bodyInterface.CreateBody(floorSettings);
    bodyInterface.AddBody(floor->GetID(), EActivation::DontActivate);

    RefConst<Shape> diceShape = new BoxShape(Vec3(0.1f, 0.1f, 0.1f));

    BodyCreationSettings diceSettings(
        diceShape,
        Vec3(0, 5, 0),
        Quat::sIdentity(),
        EMotionType::Dynamic,
        Layers::MOVING
    );

    Body* diceBody = bodyInterface.CreateBody(diceSettings);
    bodyInterface.AddBody(diceBody->GetID(), EActivation::Activate);

    TempAllocatorImpl tempAllocator(10 * 1024 * 1024);

    JobSystemThreadPool jobSystem(
        cMaxPhysicsJobs,
        cMaxPhysicsBarriers,
        std::thread::hardware_concurrency() - 1
    );

    SetTargetFPS(60);

    while (!WindowShouldClose())
    {
        float dt = GetFrameTime();

        physics.Update(dt, 1, &tempAllocator, &jobSystem);

        RVec3 pos = bodyInterface.GetPosition(diceBody->GetID());
        Quat rot = bodyInterface.GetRotation(diceBody->GetID());

        Vector3 position = { (float)pos.GetX(), (float)pos.GetY(), (float)pos.GetZ() };

        Vec3 axis{};
        float angle;
        rot.GetAxisAngle(axis, angle);

        Vector3 axisRL = { axis.GetX(), axis.GetY(), axis.GetZ() };

        BeginDrawing();
        ClearBackground(::RAYWHITE);

        BeginMode3D(camera);

        DrawModelEx(
            model,
            position,
            axisRL,
            angle * RAD2DEG,
            (Vector3){ 0.01f,0.01f,0.01f },
            ::WHITE
        );

        DrawCube((Vector3){0,-1,0}, 20, 1, 20, ::GRAY);
        DrawGrid(10, 1.0f);

        EndMode3D();

        DrawFPS(10, 10);
        EndDrawing();
    }

    UnloadModel(model);
    CloseWindow();

    return 0;
}