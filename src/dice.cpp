#include "dice.h"

Dice::Dice(const Model& model)
{
    this->model = &model;

    const JPH::RefConst<JPH::Shape> diceShape = new JPH::BoxShape(JPH::Vec3(0.01f, 0.01f, 0.01f));

    JPH::BodyCreationSettings diceSettings(
        diceShape,
        JPH::Vec3(0, 5, 0),
        JPH::Quat::sIdentity(),
        JPH::EMotionType::Dynamic,
        Layers::MOVING
    );

    this->diceBody = Physics::GetBodyInterface().CreateBody(diceSettings);
    Physics::GetBodyInterface().AddBody(this->diceBody->GetID(), JPH::EActivation::Activate);
}

void Dice::Draw(float dt)
{
    const JPH::RVec3 pos = Physics::GetBodyInterface().GetPosition(this->diceBody->GetID());
    const JPH::Quat rot = Physics::GetBodyInterface().GetRotation(this->diceBody->GetID());

    this->position = { pos.GetX(), pos.GetY(), pos.GetZ() };

    JPH::Vec3 axis{};
    float angle;
    rot.GetAxisAngle(axis, angle);

    const Vector3 axisRL = { axis.GetX(), axis.GetY(), axis.GetZ() };

    DrawModelEx(
         *this->model,
         position,
         axisRL,
         angle * RAD2DEG,
         (Vector3){ 0.01f,0.01f,0.01f },
         ::WHITE
     );
}
