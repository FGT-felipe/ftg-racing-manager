<script lang="ts">
    import { uiStore } from "$lib/stores/ui.svelte";
    import ConfirmationModal from "./ConfirmationModal.svelte";
</script>

<ConfirmationModal
    isOpen={uiStore.modal.isOpen}
    title={uiStore.modal.title}
    message={uiStore.modal.message}
    type={uiStore.modal.type}
    confirmLabel={uiStore.modal.confirmLabel}
    cancelLabel={uiStore.modal.cancelLabel}
    onConfirm={uiStore.modal.onConfirm}
    onCancel={uiStore.modal.onCancel}
/>
