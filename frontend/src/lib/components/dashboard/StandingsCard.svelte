<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { universeStore } from "$lib/stores/universe.svelte";
    import { Trophy, User, Users, ChevronRight } from "lucide-svelte";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { fly } from "svelte/transition";
    import { t } from "$lib/utils/i18n";
    import { formatDriverName } from "$lib/utils/driver";

    let team = $derived(teamStore.value.team);
    let standing = $derived(
        team ? universeStore.getTeamStanding(team.id) : null,
    );
    let driverStandings = $derived(
        team ? universeStore.getDriverStandings(team.id) : [],
    );

    function getOrdinal(n: number) {
        const s = ["th", "st", "nd", "rd"];
        const v = n % 100;
        return n + (s[(v - 20) % 10] || s[v] || s[0]);
    }
</script>

<section class="flex flex-col gap-6 h-full">
    <h3
        class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
    >
        {t('championship_standings')}
    </h3>

    <div
        class="flex-1 bg-app-surface border border-app-border rounded-2xl p-8 flex flex-col gap-8 relative overflow-hidden group transition-all hover:border-app-primary/20"
    >
        <!-- Background Decoration -->
        <div
            class="absolute -right-4 -bottom-4 opacity-5 group-hover:opacity-10 transition-opacity"
        >
            <Trophy size={120} />
        </div>

        {#if universeStore.value.loading}
            <div class="flex items-center justify-center h-full">
                <div
                    class="w-6 h-6 border-2 border-app-primary border-t-transparent rounded-full animate-spin"
                ></div>
            </div>
        {:else if standing}
            <!-- Team Standing -->
            <div class="flex flex-col gap-4">
                <div class="flex items-center justify-between">
                    <div class="flex flex-col gap-1">
                        <span
                            class="text-[9px] font-black text-app-text/30 uppercase tracking-widest"
                            >{t('constructor_position')}</span
                        >
                        <div class="flex items-baseline gap-2">
                            <h4
                                class="text-3xl font-heading font-black text-app-text italic tracking-tighter uppercase"
                            >
                                {getOrdinal(standing.position)}
                            </h4>
                            <span
                                class="text-xs font-bold text-app-text/20 whitespace-nowrap"
                                >{t('of_x_teams', { total: standing.total })}</span
                            >
                        </div>
                    </div>
                    <div class="p-3 bg-app-text/5 rounded-xl text-app-primary">
                        <Trophy size={20} />
                    </div>
                </div>

                <div class="flex items-center gap-2">
                    <span class="text-[10px] font-bold text-app-primary"
                        >{standing.points}</span
                    >
                    <span
                        class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                        >{t('points_season_total')}</span
                    >
                </div>
            </div>

            <div class="h-px w-full bg-app-text/5"></div>

            <!-- Drivers Standing -->
            <div class="flex flex-col gap-4">
                <span
                    class="text-[9px] font-black text-app-text/30 uppercase tracking-widest"
                    >{t('our_pilots')}</span
                >

                <div class="flex flex-col gap-3">
                    {#each driverStandings as driver (driver.id)}
                        <div
                            class="flex items-center justify-between p-3 bg-app-text/20 rounded-xl border border-app-border group/driver hover:border-app-primary/20 transition-all"
                        >
                            <div class="flex items-center gap-3">
                                <div
                                    class="w-8 h-8 rounded-full bg-app-text/5 flex items-center justify-center overflow-hidden"
                                >
                                    <DriverAvatar
                                        id={driver.id}
                                        gender={driver.gender}
                                        class="w-full h-full"
                                    />
                                </div>
                                <div class="flex flex-col">
                                    <div class="flex items-center gap-1.5">
                                        <span
                                            class="text-[10px] font-black text-app-text uppercase italic"
                                            title={driver.name}
                                            >{formatDriverName(driver.name)}</span
                                        >
                                        <CountryFlag countryCode={driver.countryCode} size="xs" />
                                    </div>
                                    <span
                                        class="text-[8px] font-bold text-app-text/30 uppercase tracking-tighter pt-0.5"
                                        >{driver.seasonPoints} {t('col_pts_abbr')}</span
                                    >
                                </div>
                            </div>
                            <div class="flex flex-col items-end">
                                <span
                                    class="text-xs font-heading font-black text-app-primary italic"
                                    >{getOrdinal(driver.position)}</span
                                >
                            </div>
                        </div>
                    {/each}
                </div>
            </div>

            <a
                href="/season"
                class="flex items-center gap-2 text-[10px] font-black text-app-text/40 uppercase tracking-widest mt-auto group/link hover:text-app-text transition-all pt-4"
            >
                {t('full_standings')} <ChevronRight
                    size={14}
                    class="group-hover/link:translate-x-1 transition-transform"
                />
            </a>
        {:else}
            <div
                class="flex flex-col items-center justify-center h-full text-center opacity-20 gap-4"
            >
                <Users size={32} />
                <span class="text-[10px] font-black uppercase"
                    >{t('standings_unavailable')}</span
                >
            </div>
        {/if}
    </div>
</section>
