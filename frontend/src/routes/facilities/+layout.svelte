<script lang="ts">
    import SubNavbar from "$lib/components/layout/SubNavbar.svelte";

    let { children } = $props();
</script>

<div class="flex flex-col w-full h-full">
    <SubNavbar />
    <div class="flex-1 w-full overflow-y-auto">
        {@render children()}
    </div>
</div>
