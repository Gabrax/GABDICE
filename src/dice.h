#pragma once
#include "raylib.h"

#include "physics.h"

struct Dice
{
    Dice(const Model& model);
    ~Dice() = default;

    void Draw(float dt);

private:
    Vector3 position = {};
    const Model* model = nullptr;
    JPH::Body* diceBody = nullptr;
};
