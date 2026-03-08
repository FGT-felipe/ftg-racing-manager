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

<div class="w-full bg-[#15151E] overflow-hidden">
    <!-- Fixed Header -->
    <div
        class="flex items-center w-full px-[20px] py-[12px] bg-white/[0.03] border-b border-white/[0.05]"
    >
        {#each columns as col, i}
            <div
                class="font-heading font-bold text-[10px] tracking-[1.1px] text-white/40 uppercase"
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
                class="flex items-center w-full px-[20px] py-[14px] border-b-[0.5px] border-white/[0.05] transition duration-150 ease-in-out cursor-default
               {isHighlighted
                    ? 'bg-[#00C853]/10 border-l-[4px] border-l-[#00C853]'
                    : ''}
               {!isHighlighted && isOdd ? 'bg-white/[0.01]' : ''}
               {!isHighlighted && !isOdd ? 'bg-transparent' : ''}
               {!isHighlighted ? 'hover:bg-[#00C853]/5' : ''}"
            >
                {#each row as cell, colIndex}
                    <div
                        class="font-sans text-[12px]
                   {isHighlighted
                            ? 'text-[#00C853] font-black'
                            : colIndex === 0
                              ? 'text-white/50 font-medium'
                              : colIndex === columns.length - 1
                                ? 'text-white/90 font-bold'
                                : 'text-white/90 font-medium'}"
                        style="flex: {getFlex(colIndex)};"
                    >
                        {cell}
                    </div>
                {/each}
            </div>
        {/each}
    </div>
</div>
