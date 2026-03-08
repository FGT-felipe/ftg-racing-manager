<script lang="ts">
    import { page } from "$app/stores";

    let currentPath = $derived($page.url.pathname);

    const subLinks = [
        { name: "OFFICE", path: "/facilities/office" },
        { name: "GARAGE", path: "/facilities/garage" },
    ];
</script>

<div
    class="h-[45px] w-full bg-app-surface border-b border-app-border flex items-center px-6 gap-6 shrink-0"
>
    {#each subLinks as link}
        <a
            href={link.path}
            class="uppercase text-[11px] font-black tracking-wider transition-colors h-full flex items-center border-b-2 {currentPath.startsWith(
                link.path,
            )
                ? 'text-app-accent border-app-accent'
                : 'text-app-text/50 border-transparent hover:text-app-text'}"
        >
            {link.name}
        </a>
    {/each}
</div>
