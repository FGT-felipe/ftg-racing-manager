<script lang="ts">
    import AppLogo from "$lib/components/AppLogo.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { Mail, Lock, Loader2, AlertCircle } from "lucide-svelte";

    let email = $state("");
    let password = $state("");
    let isRegistering = $state(false);
    let errorMsg = $state<string | null>(null);
    let isProcessing = $state(false);

    async function handleEmailAuth(e: Event) {
        e.preventDefault();
        if (!email || !password) {
            errorMsg = "Please fill in all fields.";
            return;
        }

        isProcessing = true;
        errorMsg = null;

        try {
            if (isRegistering) {
                await authStore.registerWithEmail(email, password);
            } else {
                await authStore.loginWithEmail(email, password);
            }
        } catch (error: any) {
            console.error("Auth error:", error);
            errorMsg = error.message || "Authentication failed.";
        } finally {
            isProcessing = false;
        }
    }

    async function handleGoogleLogin() {
        isProcessing = true;
        errorMsg = null;
        try {
            await authStore.loginWithGoogle();
        } catch (error: any) {
            console.error("Google Auth error:", error);
            errorMsg = error.message || "Google authentication failed.";
        } finally {
            isProcessing = false;
        }
    }
</script>

<div
    class="relative flex min-h-screen w-full flex-col items-center justify-center p-6 bg-center bg-no-repeat overflow-hidden"
    style="background-image: url('/login_image.png'); background-size: 100% 100%;"
>
    <!-- Subtle deep overlay -->
    <div class="absolute inset-0 bg-black/85"></div>

    <div class="relative max-w-md w-full flex flex-col items-center gap-10">
        <!-- Header Section -->
        <div class="flex flex-col items-center gap-6">
            <div class="scale-125 drop-shadow-[0_0_15px_rgba(255,255,255,0.1)]">
                <AppLogo size={56} />
            </div>
            <p
                class="font-raleway text-sm text-app-primary italic uppercase tracking-[0.25em] font-bold drop-shadow-sm"
            >
                Your team, your strategy, your glory.
            </p>
        </div>

        <!-- Auth Card - Transparent Luxury -->
        <div
            class="w-full bg-black/40 backdrop-blur-xl border border-app-primary/30 p-10 rounded-[2.5rem] shadow-2xl flex flex-col gap-8"
        >
            <!-- Google Login (Luxury Style) -->
            <button
                type="button"
                onclick={handleGoogleLogin}
                disabled={isProcessing}
                class="w-full bg-black hover:bg-white/5 text-app-primary border border-app-primary rounded-2xl py-4 flex items-center justify-center gap-3 transition-all disabled:opacity-50 group font-bold tracking-widest text-[11px] uppercase"
            >
                <img
                    src="https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg"
                    alt="G"
                    class="w-5 h-5 group-hover:scale-110 transition-transform brightness-125"
                />
                <span>Sign in with Google</span>
            </button>

            <!-- Separator -->
            <div class="flex items-center gap-4 px-2">
                <div class="h-[1px] flex-1 bg-app-primary/20"></div>
                <span
                    class="text-[10px] uppercase font-bold tracking-[0.2em] text-app-primary/40 whitespace-nowrap"
                    >Or Use Email</span
                >
                <div class="h-[1px] flex-1 bg-app-primary/20"></div>
            </div>

            <!-- Error Banner -->
            {#if errorMsg}
                <div
                    class="flex items-start gap-3 p-4 bg-app-error/10 border border-app-error/20 rounded-xl text-app-error"
                >
                    <AlertCircle size={16} class="mt-0.5 shrink-0" />
                    <p class="text-xs leading-relaxed font-medium">
                        {errorMsg}
                    </p>
                </div>
            {/if}

            <form onsubmit={handleEmailAuth} class="flex flex-col gap-5 w-full">
                <!-- Email Input -->
                <div class="relative flex items-center text-app-text group">
                    <div
                        class="absolute left-6 opacity-40 group-focus-within:opacity-100 group-focus-within:text-app-primary transition-all"
                    >
                        <Mail size={18} />
                    </div>
                    <input
                        type="email"
                        bind:value={email}
                        disabled={isProcessing}
                        placeholder="Email Address"
                        class="w-full bg-black/60 border border-white/5 rounded-2xl py-4.5 pl-16 pr-6 text-sm focus:outline-none focus:border-app-primary transition-all disabled:opacity-50 placeholder:text-app-text/20"
                        required
                    />
                </div>

                <!-- Password Input -->
                <div class="relative flex items-center text-app-text group">
                    <div
                        class="absolute left-6 opacity-40 group-focus-within:opacity-100 group-focus-within:text-app-primary transition-all"
                    >
                        <Lock size={18} />
                    </div>
                    <input
                        type="password"
                        bind:value={password}
                        disabled={isProcessing}
                        placeholder="Password"
                        class="w-full bg-black/60 border border-white/5 rounded-2xl py-4.5 pl-16 pr-6 text-sm focus:outline-none focus:border-app-primary transition-all disabled:opacity-50 placeholder:text-app-text/20"
                        required
                    />
                </div>

                <!-- Primary Sign In Button (Solid Gold) -->
                <button
                    type="submit"
                    disabled={isProcessing}
                    class="w-full bg-app-primary hover:brightness-110 active:scale-[0.98] text-app-primary-foreground rounded-2xl py-4.5 flex items-center justify-center gap-3 transition-all mt-4 disabled:opacity-50 font-black tracking-[0.2em] text-[11px] shadow-lg shadow-app-primary/20 uppercase"
                >
                    {#if isProcessing}
                        <Loader2
                            size={18}
                            class="animate-spin text-app-primary-foreground"
                        />
                        <span>PROCESSING...</span>
                    {:else}
                        <span>{isRegistering ? "Register Now" : "SIGN IN"}</span
                        >
                    {/if}
                </button>
            </form>
        </div>

        <!-- Toggle Mode -->
        <button
            type="button"
            disabled={isProcessing}
            onclick={() => {
                isRegistering = !isRegistering;
                errorMsg = null;
            }}
            class="group flex flex-col items-center gap-3 disabled:opacity-50 transition-all hover:-translate-y-1"
        >
            <span
                class="text-app-text/30 text-[10px] font-bold tracking-[0.3em] uppercase"
            >
                {isRegistering ? "Already a Member?" : "New Manager?"}
            </span>
            <span
                class="text-white group-hover:text-app-primary transition-colors text-[11px] font-black tracking-[0.25em] uppercase border-b-2 border-app-primary/20 group-hover:border-app-primary pb-1"
            >
                {isRegistering ? "Back to Login" : "Join Here"}
            </span>
        </button>
    </div>
</div>
