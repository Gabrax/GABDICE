<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>{{ config('app.name', 'Laravel') }}</title>

    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=instrument-sans:400,500,600" rel="stylesheet" />

    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

<body class="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500">

<div class="w-full max-w-md">

    <!-- Logo / Title -->
    <div class="text-center mb-8 text-white">
        <h1 class="text-4xl font-bold tracking-wide">{{ config('app.name') }}</h1>
        <p class="opacity-80 mt-2">Welcome back 👋</p>
    </div>

    <!-- Card -->
    <div class="backdrop-blur-xl bg-white/20 border border-white/30 shadow-2xl rounded-2xl p-8 text-white">

        <!-- Tabs -->
        <div class="flex mb-6 bg-white/10 rounded-xl p-1">
            <button onclick="showLogin()" id="loginTab"
                class="w-1/2 py-2 rounded-lg font-semibold bg-white text-purple-600 transition">
                Login
            </button>
            <button onclick="showRegister()" id="registerTab"
                class="w-1/2 py-2 rounded-lg font-semibold transition">
                Register
            </button>
        </div>

        <!-- Login Form -->
        <form id="loginForm" method="POST" action="{{ route('login') }}" class="space-y-4">
            @csrf

            <input type="email" name="email" placeholder="Email"
                class="w-full px-4 py-3 rounded-xl bg-white/20 placeholder-white/70 focus:outline-none focus:ring-2 focus:ring-white">

            <input type="password" name="password" placeholder="Password"
                class="w-full px-4 py-3 rounded-xl bg-white/20 placeholder-white/70 focus:outline-none focus:ring-2 focus:ring-white">

            <button type="submit"
                class="w-full bg-white text-purple-600 font-bold py-3 rounded-xl hover:scale-105 transition">
                Login
            </button>
        </form>

        <!-- Register Form -->
        <form id="registerForm" method="POST" action="{{ route('register') }}" class="space-y-4 hidden">
            @csrf

            <input type="text" name="name" placeholder="Full Name"
                class="w-full px-4 py-3 rounded-xl bg-white/20 placeholder-white/70 focus:outline-none focus:ring-2 focus:ring-white">

            <input type="email" name="email" placeholder="Email"
                class="w-full px-4 py-3 rounded-xl bg-white/20 placeholder-white/70 focus:outline-none focus:ring-2 focus:ring-white">

            <input type="password" name="password" placeholder="Password"
                class="w-full px-4 py-3 rounded-xl bg-white/20 placeholder-white/70 focus:outline-none focus:ring-2 focus:ring-white">

            <input type="password" name="password_confirmation" placeholder="Confirm Password"
                class="w-full px-4 py-3 rounded-xl bg-white/20 placeholder-white/70 focus:outline-none focus:ring-2 focus:ring-white">

            <button type="submit"
                class="w-full bg-white text-purple-600 font-bold py-3 rounded-xl hover:scale-105 transition">
                Create Account
            </button>
        </form>

    </div>

</div>

<script>
    function showLogin() {
        document.getElementById('loginForm').classList.remove('hidden');
        document.getElementById('registerForm').classList.add('hidden');

        document.getElementById('loginTab').classList.add('bg-white','text-purple-600');
        document.getElementById('registerTab').classList.remove('bg-white','text-purple-600');
    }

    function showRegister() {
        document.getElementById('registerForm').classList.remove('hidden');
        document.getElementById('loginForm').classList.add('hidden');

        document.getElementById('registerTab').classList.add('bg-white','text-purple-600');
        document.getElementById('loginTab').classList.remove('bg-white','text-purple-600');
    }
</script>

</body>
</html>
