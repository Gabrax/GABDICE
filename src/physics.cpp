#include "physics.h"

using namespace JPH;

struct BroadPhaseLayerInterfaceImpl final : BroadPhaseLayerInterface
{
    BroadPhaseLayerInterfaceImpl()
    {
        mObjectToBroadPhase[Layers::NON_MOVING] = BroadPhaseLayer(0);
        mObjectToBroadPhase[Layers::MOVING] = BroadPhaseLayer(1);
    }

    [[nodiscard]] uint GetNumBroadPhaseLayers() const override
    {
        return 2;
    }

    [[nodiscard]] BroadPhaseLayer GetBroadPhaseLayer(ObjectLayer inLayer) const override
    {
        return mObjectToBroadPhase[inLayer];
    }

#if defined(JPH_EXTERNAL_PROFILE) || defined(JPH_PROFILE_ENABLED)
    const char* GetBroadPhaseLayerName(BroadPhaseLayer inLayer) const override
    {
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

struct ObjectLayerPairFilterImpl : ObjectLayerPairFilter
{
    [[nodiscard]] bool ShouldCollide(ObjectLayer inLayer1, ObjectLayer inLayer2) const override
    {
        return true;
    }
};

struct ObjectVsBroadPhaseLayerFilterImpl : ObjectVsBroadPhaseLayerFilter
{
    [[nodiscard]] bool ShouldCollide(ObjectLayer, BroadPhaseLayer) const override
    {
        return true;
    }
};

static PhysicsSystem* physics = nullptr;

static BroadPhaseLayerInterfaceImpl broadPhaseLayerInterface;
static ObjectVsBroadPhaseLayerFilterImpl objectVsBroadPhaseLayerFilter;
static ObjectLayerPairFilterImpl objectLayerPairFilter;

static TempAllocatorImpl* tempAllocator = nullptr;
static JobSystemThreadPool* jobSystem = nullptr;

void Physics::Init()
{
    RegisterDefaultAllocator();

    Factory::sInstance = new Factory();
    RegisterTypes();

    physics = new PhysicsSystem();

    physics->Init(
        1024, 0, 1024, 1024,
        broadPhaseLayerInterface,
        objectVsBroadPhaseLayerFilter,
        objectLayerPairFilter
    );

    physics->SetGravity(Vec3(0, -9.81f, 0));

    tempAllocator = new TempAllocatorImpl(10 * 1024 * 1024);

    uint numThreads = std::max(1u, std::thread::hardware_concurrency() - 1);

    jobSystem = new JobSystemThreadPool(
        cMaxPhysicsJobs,
        cMaxPhysicsBarriers,
        numThreads
    );

    const RefConst<Shape> floorShape = new BoxShape(Vec3(10, 0.5f, 10));

    const BodyCreationSettings floorSettings(
        floorShape,
        Vec3(0, -1, 0),
        Quat::sIdentity(),
        EMotionType::Static,
        Layers::NON_MOVING
    );

    const Body* floor = GetBodyInterface().CreateBody(floorSettings);
    GetBodyInterface().AddBody(floor->GetID(), EActivation::DontActivate);
}

void Physics::Cleanup() {
}

void Physics::Update(float dt)
{
    physics->Update(dt, 1, tempAllocator, jobSystem);
}

JPH::BodyInterface& Physics::GetBodyInterface()
{
    return physics->GetBodyInterface();
}
