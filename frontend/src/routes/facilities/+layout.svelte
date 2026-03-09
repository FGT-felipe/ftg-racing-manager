<script lang="ts">
    let { children } = $props();
</script>

<div class="flex flex-col w-full h-full">
    <div class="w-full h-full overflow-y-auto">
        {@render children()}
    </div>
</div>
