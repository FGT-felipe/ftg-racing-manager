<script lang="ts">
  import { X, AlertTriangle, Info, CheckCircle2 } from "lucide-svelte";
  import { fade, fly } from "svelte/transition";

  interface Props {
    isOpen: boolean;
    title: string;
    message: string;
    confirmLabel?: string;
    cancelLabel?: string;
    type?: "danger" | "warning" | "info" | "success";
    isLoading?: boolean;
    onConfirm: () => void;
    onCancel: () => void;
  }

  let {
    isOpen,
    title,
    message,
    confirmLabel = "Confirm",
    cancelLabel = "Cancel",
    type = "info",
    isLoading = false,
    onConfirm,
    onCancel,
  }: Props = $props();

  const typeConfig = {
    danger: {
      icon: AlertTriangle,
      iconClass: "text-red-500",
      bgClass: "bg-red-500/10",
      borderClass: "border-red-500/20",
      btnClass: "bg-red-500 text-white hover:bg-red-600",
    },
    warning: {
      icon: AlertTriangle,
      iconClass: "text-yellow-500",
      bgClass: "bg-yellow-500/10",
      borderClass: "border-yellow-500/20",
      btnClass: "bg-yellow-500 text-black hover:bg-yellow-600",
    },
    info: {
      icon: Info,
      iconClass: "text-app-primary",
      bgClass: "bg-app-primary/10",
      borderClass: "border-app-primary/20",
      btnClass: "bg-app-primary text-app-primary-foreground hover:opacity-90",
    },
    success: {
      icon: CheckCircle2,
      iconClass: "text-emerald-500",
      bgClass: "bg-emerald-500/10",
      borderClass: "border-emerald-500/20",
      btnClass: "bg-emerald-500 text-white hover:bg-emerald-600",
    },
  };

  let config = $derived(typeConfig[type]);
</script>

{#if isOpen}
  <div
    class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-app-bg/80 backdrop-blur-md"
    transition:fade={{ duration: 200 }}
  >
    <!-- Backdrop overlay -->
    <button
      class="absolute inset-0 cursor-default border-none bg-transparent w-full h-full"
      onclick={onCancel}
      aria-label="Close"
    ></button>

    <!-- Modal Content -->
    <div
      class="relative w-full max-w-md bg-app-surface border border-app-border rounded-[32px] overflow-hidden shadow-2xl p-8"
      transition:fly={{ y: 20, duration: 300 }}
    >
      <div class="flex flex-col items-center text-center gap-6">
        <!-- Icon -->
        <div class="p-4 rounded-3xl {config.bgClass} {config.borderClass} border">
          <config.icon size={32} class={config.iconClass} />
        </div>

        <div class="space-y-2">
          <h3 class="text-xl font-heading font-black uppercase italic tracking-tighter text-app-text">
            {title}
          </h3>
          <p class="text-sm text-app-text/60 font-medium leading-relaxed">
            {message}
          </p>
        </div>

        <div class="flex gap-3 w-full mt-2">
          <button
            onclick={onCancel}
            disabled={isLoading}
            class="flex-1 py-4 px-6 bg-app-text/5 border border-app-border rounded-2xl text-[10px] font-black uppercase tracking-widest text-app-text/40 hover:bg-app-text/10 hover:text-app-text transition-all disabled:opacity-50"
          >
            {cancelLabel}
          </button>
          <button
            onclick={onConfirm}
            disabled={isLoading}
            class="flex-1 py-4 px-6 rounded-2xl text-[10px] font-black uppercase tracking-widest transition-all shadow-lg flex items-center justify-center gap-2 {config.btnClass} disabled:opacity-50"
          >
            {#if isLoading}
              <div class="w-3 h-3 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
            {/if}
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  </div>
{/if}
