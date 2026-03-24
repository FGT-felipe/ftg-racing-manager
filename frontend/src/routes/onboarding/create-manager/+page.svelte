<script lang="ts">
    import { managerStore } from "$lib/stores/manager.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { goto } from "$app/navigation";
    import {
        Users,
        Trophy,
        PieChart,
        Gavel,
        Wrench,
        ChevronRight,
        Type,
        Globe,
        Sparkles,
    } from "lucide-svelte";
    import { fly, fade } from "svelte/transition";
    import { MANAGER_ROLES } from "$lib/constants/manager";

    let firstName = $state("");
    let lastName = $state("");
    let nationality = $state("BR");
    let gender = $state("Male");
    let day = $state("");
    let month = $state("");
    let year = $state("");
    let selectedRoleId = $state("");
    let isSubmitting = $state(false);

    const roles = MANAGER_ROLES;

    async function handleEstablishCareer() {
        if (!firstName || !lastName || !day || !month || !year) return;

        isSubmitting = true;
        try {
            // Explicitly convert to string and pad
            const m = String(month).padStart(2, "0");
            const d = String(day).padStart(2, "0");
            const birthDate = `${year}-${m}-${d}`;

            await managerStore.createProfile({
                firstName,
                lastName,
                nationality,
                country: nationality, // Save as both for consistency
                gender,
                birthDate,
                backgroundId: selectedRoleId,
            });
            goto("/onboarding/team-selection");
        } catch (error) {
            console.error("Error creating manager profile:", error);
        } finally {
            isSubmitting = false;
        }
    }
</script>

<div class="min-h-screen bg-app-bg text-app-text p-6 md:p-12 overflow-x-hidden">
    <div class="max-w-6xl mx-auto flex flex-col gap-12">
        <!-- Header -->
        <header
            class="flex flex-col gap-4 text-center md:text-left"
            in:fly={{ y: -20, duration: 600 }}
        >
            <div
                class="flex items-center justify-center md:justify-start gap-4 text-app-primary"
            >
                <Users size={32} />
                <span class="text-xs font-black uppercase tracking-[0.4em]"
                    >Career Path Initiation</span
                >
            </div>
            <h1
                class="text-5xl md:text-7xl font-heading font-black tracking-tighter uppercase italic leading-none"
            >
                Create Your <span class="text-app-primary">Manager</span> Profile
            </h1>
            <p
                class="text-app-text/40 font-bold uppercase tracking-widest text-xs max-w-2xl"
            >
                Define your professional background and personal details to
                begin your journey in the world of professional racing
                management.
            </p>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-start">
            <!-- Left: Personal Forms (4 cols) -->
            <div
                class="lg:col-span-12 xl:col-span-4 flex flex-col gap-8"
                in:fly={{ x: -20, duration: 600, delay: 200 }}
            >
                <section
                    class="bg-app-text/5 border border-app-border rounded-3xl p-8 flex flex-col gap-8"
                >
                    <div class="flex items-center gap-3 text-app-primary">
                        <Type size={18} />
                        <h2
                            class="text-sm font-black uppercase tracking-widest"
                        >
                            Personal Identification
                        </h2>
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div class="flex flex-col gap-2">
                            <label
                                for="firstName"
                                class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                                >First Name</label
                            >
                            <input
                                id="firstName"
                                type="text"
                                bind:value={firstName}
                                placeholder="Ayrton"
                                class="w-full bg-app-surface border border-app-border rounded-xl px-4 py-3 text-sm focus:border-app-primary outline-none transition-all"
                            />
                        </div>
                        <div class="flex flex-col gap-2">
                            <label
                                for="lastName"
                                class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                                >Last Name</label
                            >
                            <input
                                id="lastName"
                                type="text"
                                bind:value={lastName}
                                placeholder="Senna"
                                class="w-full bg-app-surface border border-app-border rounded-xl px-4 py-3 text-sm focus:border-app-primary outline-none transition-all"
                            />
                        </div>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label
                            for="nationality"
                            class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                            >Nationality</label
                        >
                        <div class="relative">
                            <Globe
                                size={14}
                                class="absolute left-4 top-1/2 -translate-y-1/2 text-app-text/20"
                            />
                            <select
                                id="nationality"
                                bind:value={nationality}
                                class="w-full bg-app-surface border border-app-border rounded-xl px-12 py-3 text-sm focus:border-app-primary outline-none appearance-none transition-all"
                            >
                                <option value="BR">Brazil</option>
                                <option value="AR">Argentina</option>
                                <option value="CO">Colombia</option>
                                <option value="MX">Mexico</option>
                                <option value="UY">Uruguay</option>
                                <option value="CL">Chile</option>
                                <option value="US">United States</option>
                                <option value="GB">United Kingdom</option>
                            </select>
                        </div>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label
                            for="gender"
                            class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                            >Gender Identity</label
                        >
                        <select
                            id="gender"
                            bind:value={gender}
                            class="w-full bg-app-surface border border-app-border rounded-xl px-4 py-3 text-sm focus:border-app-primary outline-none appearance-none transition-all"
                        >
                            <option>Male</option>
                            <option>Female</option>
                            <option>Non-binary</option>
                        </select>
                    </div>

                    <div class="flex flex-col gap-2">
                        <label
                            for="dob"
                            class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                            >Date of Birth</label
                        >
                        <div class="grid grid-cols-3 gap-2">
                            <input
                                type="number"
                                bind:value={day}
                                placeholder="DD"
                                class="w-full bg-app-surface border border-app-border rounded-xl px-4 py-3 text-sm text-center outline-none focus:border-app-primary transition-all"
                            />
                            <input
                                type="number"
                                bind:value={month}
                                placeholder="MM"
                                class="w-full bg-app-surface border border-app-border rounded-xl px-4 py-3 text-sm text-center outline-none focus:border-app-primary transition-all"
                            />
                            <input
                                type="number"
                                bind:value={year}
                                placeholder="YYYY"
                                class="w-full bg-app-surface border border-app-border rounded-xl px-4 py-3 text-sm text-center outline-none focus:border-app-primary transition-all"
                            />
                        </div>
                    </div>
                </section>
            </div>

            <!-- Right: Role Selection (8 cols) -->
            <div
                class="lg:col-span-12 xl:col-span-8 flex flex-col gap-8"
                in:fly={{ x: 20, duration: 600, delay: 400 }}
            >
                <section class="flex flex-col gap-6">
                    <div class="flex items-center gap-3 text-app-primary">
                        <Sparkles size={18} />
                        <h2
                            class="text-sm font-black uppercase tracking-widest"
                        >
                            Select Your Professional Background
                        </h2>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {#each roles as role}
                            <button
                                onclick={() => (selectedRoleId = role.id)}
                                class="flex flex-col items-start gap-4 p-6 bg-app-text/5 border transition-all duration-300 rounded-[32px] text-left group
                                {selectedRoleId === role.id
                                    ? 'border-app-primary bg-app-primary/5 shadow-2xl'
                                    : 'border-app-border hover:border-app-border'}"
                            >
                                <div class="flex items-center gap-4">
                                    <div
                                        class="p-3 rounded-2xl bg-app-text/5 group-hover:bg-app-primary/20 transition-colors"
                                    >
                                        <role.icon
                                            size={24}
                                            class={selectedRoleId === role.id
                                                ? "text-app-primary"
                                                : "text-app-text/40"}
                                        />
                                    </div>
                                    <div class="flex flex-col">
                                        <h3
                                            class="font-heading font-black uppercase text-lg tracking-tight italic"
                                        >
                                            {role.title}
                                        </h3>
                                        <p
                                            class="text-[10px] text-app-text/40 font-bold uppercase tracking-wider"
                                        >
                                            {role.desc}
                                        </p>
                                    </div>
                                </div>

                                <div class="flex flex-col gap-3 w-full mt-2">
                                    <div class="flex flex-col gap-1.5">
                                        {#each role.pros as pro}
                                            <div
                                                class="flex items-center gap-2 text-[11px] font-bold text-green-400/80"
                                            >
                                                <div
                                                    class="w-1 h-1 rounded-full bg-green-400"
                                                ></div>
                                                {pro}
                                            </div>
                                        {/each}
                                    </div>
                                    <div
                                        class="flex flex-col gap-1.5 opacity-50"
                                    >
                                        {#each role.cons as con}
                                            <div
                                                class="flex items-center gap-2 text-[11px] font-bold text-red-400/80"
                                            >
                                                <div
                                                    class="w-1 h-1 rounded-full bg-red-400"
                                                ></div>
                                                {con}
                                            </div>
                                        {/each}
                                    </div>
                                </div>
                            </button>
                        {/each}
                    </div>
                </section>

                <!-- Footer Summary & Submit -->
                <footer
                    class="flex flex-col md:flex-row items-center justify-between gap-8 pt-8 border-t border-app-border mt-4"
                >
                    <div
                        class="flex flex-col gap-1 max-w-md text-center md:text-left"
                    >
                        <p
                            class="text-xs font-bold text-app-text/30 uppercase tracking-widest italic leading-relaxed"
                        >
                            "The first step towards greatness is choosing the
                            path that defines you. Your background will
                            influence every decision from this moment on."
                        </p>
                    </div>

                    <button
                        onclick={handleEstablishCareer}
                        disabled={!firstName ||
                            !lastName ||
                            !day ||
                            !month ||
                            !year ||
                            !selectedRoleId ||
                            isSubmitting}
                        class="px-12 py-5 bg-app-primary rounded-full hover:shadow-[0_0_40px_rgba(197,160,89,0.3)] transition-all flex items-center gap-4 disabled:opacity-20 disabled:grayscale group"
                    >
                        {#if isSubmitting}
                            <div
                                class="w-5 h-5 border-2 border-app-primary-foreground border-t-transparent rounded-full animate-spin"
                            ></div>
                            <span
                                class="font-heading font-black text-app-primary-foreground text-sm uppercase tracking-widest italic"
                                >Wait...</span
                            >
                        {:else}
                            <span
                                class="font-heading font-black text-app-primary-foreground text-sm uppercase tracking-widest italic"
                                >Establish Career</span
                            >
                            <ChevronRight
                                size={18}
                                class="text-app-primary-foreground group-hover:translate-x-1 transition-transform"
                            />
                        {/if}
                    </button>
                </footer>
            </div>
        </div>
    </div>
</div>

<style>
    /* Custom refined scrollbar for the page */
    :global(body) {
        scrollbar-width: thin;
        scrollbar-color: var(--primary-color) var(--bg-color);
    }
    :global(::-webkit-scrollbar) {
        width: 8px;
    }
    :global(::-webkit-scrollbar-track) {
        background: var(--bg-color);
    }
    :global(::-webkit-scrollbar-thumb) {
        background: var(--primary-color);
        border-radius: 20px;
    }
</style>
