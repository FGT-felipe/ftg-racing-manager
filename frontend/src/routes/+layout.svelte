<script lang="ts">
  import "../app.css";
  import "$lib/firebase/config";
  import { browser } from "$app/environment";
  import { page } from "$app/stores";
  import { fly } from "svelte/transition";
  import AppHeader from "$lib/components/layout/AppHeader.svelte";
  import AppLogo from "$lib/components/AppLogo.svelte";
  import LoginScreen from "$lib/components/auth/LoginScreen.svelte";
  import { goto } from "$app/navigation";
  import {
    LayoutDashboard,
    Briefcase,
    GraduationCap,
    Factory,
    Flag,
    Users,
    Trophy,
    Sun,
    Moon,
  } from "lucide-svelte";
  import { themeStore } from "$lib/stores/theme.svelte";
  import { authStore } from "$lib/stores/auth.svelte";
  import { teamStore } from "$lib/stores/team.svelte";
  import { seasonStore } from "$lib/stores/season.svelte";
  import { notificationStore } from "$lib/stores/notifications.svelte";
  import { transactionStore } from "$lib/stores/transactions.svelte";
  import { managerStore } from "$lib/stores/manager.svelte";
  import { universeStore } from "$lib/stores/universe.svelte";
  import { driverStore } from "$lib/stores/driver.svelte";
  import GlobalModal from "$lib/components/ui/GlobalModal.svelte";

  let { children } = $props();

  const navItems = [
    { name: "Dashboard", path: "/", icon: LayoutDashboard },
    { name: "Management", path: "/management", icon: Briefcase },
    { name: "Academy", path: "/academy", icon: GraduationCap },
    { name: "Facilities", path: "/facilities", icon: Factory },
    { name: "Racing", path: "/racing", icon: Flag },
    { name: "Market", path: "/market", icon: Users },
    { name: "Season", path: "/season", icon: Trophy },
  ];

  let currentPath = $derived($page.url.pathname);

  function isActive(path: string) {
    if (path === "/") {
      return currentPath === path;
    }
    return currentPath.startsWith(path);
  }

  // Effect to toggle the 'dark' class on the root html element
  $effect(() => {
    if (browser) {
      if (themeStore.value === "dark") {
        document.documentElement.classList.add("dark");
      } else {
        document.documentElement.classList.remove("dark");
      }
    }
  });

  // Re-initialized Team Store strictly on Auth lifecycle
  $effect(() => {
    if (browser && !authStore.loading) {
      teamStore.init(authStore.user);
    }
  });

  // Keep Season Store in sync with Team Lifecycle
  // Priority: universe.activeSeasonId (canonical, updated by post-race sync)
  // Fallback:  team.currentSeasonId   (legacy field, may be stale)
  // All leagues share one season doc per year — never one per league.
  $effect(() => {
    const team = teamStore.value.team;
    const universe = universeStore.value.universe;
    const seasonId = universe?.activeSeasonId || team?.currentSeasonId;

    if (seasonId) {
      seasonStore.init(seasonId);
    } else if (!teamStore.value.loading && !universeStore.value.loading) {
      seasonStore.init(""); // Will trigger fallback loading state finish
      if (!team) seasonStore.clear();
    }
  });

  // Initialize Stores — gated behind auth to prevent Firestore permission errors
  $effect(() => {
    if (browser && !authStore.loading && authStore.user) {
      notificationStore.init();
      transactionStore.init();
      managerStore.init();
      universeStore.init();
      driverStore.init();
    }
  });

  // Refined Routing Logic (Anti-Race Condition)
  $effect(() => {
    if (!browser) return;

    // 1. Wait for Auth
    if (authStore.loading) return;

    // 2. Unauthenticated check
    if (!authStore.user) {
      if (currentPath !== "/login") {
        goto("/login");
      }
      return;
    }

    // 3. Wait for Profile & Team Data
    if (managerStore.isLoading || teamStore.value.loading) return;

    // 4. Decision making
    const manager = managerStore.profile;
    const team = teamStore.value.team;

    // Check for Manager Profile
    if (!manager) {
      if (currentPath !== "/onboarding/create-manager") {
        console.log("No manager found, redirecting to profile creation.");
        goto("/onboarding/create-manager");
      }
      return;
    }

    // Check for Team
    if (!team) {
      // If they are on manager creation but already have a profile, move them to team selection
      if (currentPath === "/onboarding/create-manager") {
        goto("/onboarding/team-selection");
        return;
      }

      if (currentPath !== "/onboarding/team-selection") {
        console.log("No team found, redirecting to team selection.");
        goto("/onboarding/team-selection");
      }
      return;
    }

    // User has everything, block restricted paths
    const onboardingPaths = [
      "/login",
      "/onboarding/create-manager",
      "/onboarding/team-selection",
    ];
    if (onboardingPaths.includes(currentPath)) {
      console.log("All systems active, bypassing onboarding gates.");
      goto("/");
    }
  });
</script>

<div
  class="min-h-screen w-full bg-app-bg text-app-text font-poppins selection:bg-app-primary/30"
>
  {#if authStore.loading}
    <div class="flex h-full w-full items-center justify-center">
      <div class="flex flex-col items-center gap-4">
        <div
          class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
        ></div>
        <span class="text-[10px] font-black tracking-widest text-app-primary"
          >AUTHENTICATING...</span
        >
      </div>
    </div>
  {:else if currentPath === "/login" || currentPath.startsWith("/onboarding") || currentPath === "/whats-new"}
    {@render children()}
  {:else}
    <div
      class="flex flex-col h-screen w-full bg-app-bg overflow-hidden text-app-text font-sans transition-colors duration-300"
    >
      <!-- App Header Top Fixed -->
      <div class="w-full z-50 shrink-0">
        <AppHeader />
      </div>

      <!-- Main Body Container -->
      <div class="flex flex-1 overflow-hidden">
        <!-- DESKTOP SIDEBAR (>= 1024px) -->
        <aside
          class="hidden lg:flex flex-col items-center justify-between w-[94px] h-full bg-app-surface border-r border-app-border py-6 z-20 shrink-0 transition-colors duration-300"
        >
          <div class="flex flex-col items-center w-full">
            <!-- Navigation Links -->
            <nav class="flex flex-col gap-2 w-full mt-4">
              {#each navItems as item}
                {@const active = isActive(item.path)}
                <a
                  href={item.path}
                  class="flex flex-col items-center justify-center p-2 gap-1 group w-full relative"
                >
                  {#if active}
                    <div
                      class="absolute left-0 top-1 bottom-1 w-1 bg-app-primary rounded-r-md"
                    ></div>
                  {/if}

                  <div
                    class="transition-all duration-300 {active
                      ? 'text-app-primary scale-110'
                      : 'text-app-text/30 group-hover:text-app-text/70'}"
                  >
                    <item.icon size={22} strokeWidth={active ? 2.5 : 2} />
                  </div>

                  <span
                    class="uppercase text-center break-words font-heading font-black text-[8px] tracking-tighter transition-colors px-1 w-full {active
                      ? 'text-app-primary'
                      : 'text-app-text/30 group-hover:text-app-text/70'}"
                  >
                    {item.name}
                  </span>
                </a>
              {/each}
            </nav>
          </div>

          <!-- Theme Toggle Button -->
          <button
            aria-label="Toggle Theme"
            onclick={() => themeStore.toggleTheme()}
            class="flex flex-col items-center justify-center p-2 gap-1 w-full text-app-text/30 hover:text-app-text transition-colors group"
          >
            <div>
              {#if themeStore.value === "dark"}
                <Sun size={22} />
              {:else}
                <Moon size={22} />
              {/if}
            </div>
          </button>
        </aside>

        <!-- MAIN CONTENT AREA -->
        <main
          class="flex-1 relative overflow-y-auto overflow-x-hidden pb-16 lg:pb-0"
        >
          <div class="mx-auto max-w-[1600px] w-full min-h-full">
            {#key currentPath}
              <div
                in:fly={{ y: 15, duration: 400, delay: 100 }}
                out:fly={{ y: -15, duration: 300 }}
              >
                {@render children()}
              </div>
            {/key}
          </div>
        </main>
      </div>

      <!-- MOBILE BOTTOM NAV (< 1024px) -->
      <nav
        class="lg:hidden fixed bottom-0 left-0 right-0 h-16 bg-app-surface border-t border-app-border flex items-center justify-around px-2 z-50 transition-colors duration-300"
      >
        {#each navItems as item}
          {@const active = isActive(item.path)}
          <a
            href={item.path}
            class="flex flex-col items-center justify-center gap-1 w-full h-full"
          >
            <div
              class="transition-colors {active
                ? 'text-app-primary'
                : 'text-app-text/30'}"
            >
              <item.icon size={20} strokeWidth={active ? 2.5 : 2} />
            </div>
            <span
              class="text-[9px] uppercase font-black tracking-widest transition-colors {active
                ? 'text-app-primary'
                : 'text-app-text/20'}"
            >
              {item.name}
            </span>
          </a>
        {/each}
      </nav>
    </div>
  {/if}
  <GlobalModal />
</div>
