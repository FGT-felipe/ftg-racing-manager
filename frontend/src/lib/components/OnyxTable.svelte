<script lang="ts">
    type RowData = (string | number)[];

    let {
        columns = [],
        rows = [],
        flexValues = [],
        highlightIndices = [],
    } = $props<{
        columns: string[];
        rows: RowData[];
        flexValues: number[];
        highlightIndices?: number[];
    }>();

    // Helper to safely get flex-grow based on the index
    function getFlex(index: number) {
        if (flexValues && index < flexValues.length) {
            return flexValues[index];
        }
        return 1; // Default flex 1
    }
</script>

<div class="w-full bg-app-surface overflow-hidden">
    <!-- Fixed Header -->
    <div
        class="flex items-center w-full px-[20px] py-[12px] bg-app-text/[0.03] border-b border-app-border"
    >
        {#each columns as col, i}
            <div
                class="font-heading font-bold text-[10px] tracking-[1.1px] text-app-text/40 uppercase"
                style="flex: {getFlex(i)};"
            >
                {col}
            </div>
        {/each}
    </div>

    <!-- Scrollable Rows Data -->
    <div class="w-full overflow-y-auto">
        {#each rows as row, rowIndex}
            {@const isHighlighted = highlightIndices.includes(rowIndex)}
            {@const isOdd = rowIndex % 2 !== 0}

            <div
                class="flex items-center w-full px-[20px] py-[14px] border-b-[0.5px] border-app-border transition duration-150 ease-in-out cursor-default
               {isHighlighted
                    ? 'bg-app-success/10 border-l-[4px] border-l-app-success'
                    : ''}
               {!isHighlighted && isOdd ? 'bg-app-text/[0.01]' : ''}
               {!isHighlighted && !isOdd ? 'bg-transparent' : ''}
               {!isHighlighted ? 'hover:bg-app-success/5' : ''}"
            >
                {#each row as cell, colIndex}
                    <div
                        class="font-sans text-[12px]
                   {isHighlighted
                            ? 'text-app-success font-black'
                            : colIndex === 0
                              ? 'text-app-text/50 font-medium'
                              : colIndex === columns.length - 1
                                ? 'text-app-text/90 font-bold'
                                : 'text-app-text/90 font-medium'}"
                        style="flex: {getFlex(colIndex)};"
                    >
                        {cell}
                    </div>
                {/each}
            </div>
        {/each}
    </div>
</div>
