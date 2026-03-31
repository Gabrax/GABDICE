// Prevent accidentally selecting integrated GPU
#ifdef __WIN32
extern "C" {
	__declspec(dllexport) unsigned __int32 AmdPowerXpressRequestHighPerformance = 0x1;
	__declspec(dllexport) unsigned __int32 NvOptimusEnablement = 0x1;
}
#endif

#include <iostream>
#include <thread>

#include "Metal.hpp"

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

	uint GetNumBroadPhaseLayers() const override {
		return 2;
	}

	BroadPhaseLayer GetBroadPhaseLayer(ObjectLayer inLayer) const override {
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
	BroadPhaseLayer mObjectToBroadPhase[Layers::NUM_LAYERS];
};

class ObjectLayerPairFilterImpl : public ObjectLayerPairFilter {
public:
	bool ShouldCollide(ObjectLayer inLayer1, ObjectLayer inLayer2) const override {
		return true;
	}
};

class ObjectVsBroadPhaseLayerFilterImpl : public ObjectVsBroadPhaseLayerFilter {
public:
	bool ShouldCollide(ObjectLayer, BroadPhaseLayer) const override {
		return true;
	}
};

int main()
{
	MTL::Device* device = MTL::CreateSystemDefaultDevice();

	if (!device) {
		std::cout << "Failed to create Metal device\n";
		return -1;
	}

	std::cout << "Metal device created\n";

	RegisterDefaultAllocator();

	Factory::sInstance = new Factory();
	JPH::RegisterTypes();

	TempAllocatorImpl temp_allocator(10 * 1024 * 1024);

	JobSystemThreadPool job_system(
		cMaxPhysicsJobs,
		cMaxPhysicsBarriers,
		std::thread::hardware_concurrency()
	);

	BroadPhaseLayerInterfaceImpl broad_phase_layer_interface;
	ObjectVsBroadPhaseLayerFilterImpl object_vs_broadphase_layer_filter;
	ObjectLayerPairFilterImpl object_layer_pair_filter;

	PhysicsSystem physics;

	physics.Init(
		1024,
		0,
		1024,
		1024,
		broad_phase_layer_interface,
		object_vs_broadphase_layer_filter,
		object_layer_pair_filter
	);

	physics.SetGravity(Vec3(0, -9.81f, 0));

	BoxShapeSettings box(Vec3(1.0f, 1.0f, 1.0f));
	auto shape_result = box.Create();
	RefConst<Shape> shape = shape_result.Get();

	BodyCreationSettings body_settings(
		shape,
		Vec3(0, 10, 0),
		Quat::sIdentity(),
		EMotionType::Dynamic,
		Layers::MOVING
	);

	BodyInterface& body_interface = physics.GetBodyInterface();

	BodyID body_id = body_interface.CreateAndAddBody(
		body_settings,
		EActivation::Activate
	);

	for (int i = 0; i < 120; i++)
	{
		physics.Update(1.0f / 60.0f, 1, &temp_allocator, &job_system);

		Vec3 pos = body_interface.GetPosition(body_id);

		std::cout << "Y: " << pos.GetY() << std::endl;
	}

	delete Factory::sInstance;

	return 0;
}