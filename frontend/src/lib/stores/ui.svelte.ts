export type ModalType = 'info' | 'success' | 'warning' | 'danger';

interface ModalOptions {
    title: string;
    message: string;
    type?: ModalType;
    confirmLabel?: string;
    cancelLabel?: string;
    onConfirm?: () => void;
    onCancel?: () => void;
    showCancel?: boolean;
}

class UIStore {
    #modal = $state<{
        isOpen: boolean;
        title: string;
        message: string;
        type: ModalType;
        confirmLabel: string;
        cancelLabel: string;
        onConfirm: () => void;
        onCancel: () => void;
        showCancel: boolean;
    }>({
        isOpen: false,
        title: '',
        message: '',
        type: 'info',
        confirmLabel: 'Confirm',
        cancelLabel: 'Cancel',
        onConfirm: () => {},
        onCancel: () => {},
        showCancel: false
    });

    get modal() {
        return this.#modal;
    }

    alert(message: string, title: string = 'Notice', type: ModalType = 'info') {
        this.#modal = {
            isOpen: true,
            title,
            message,
            type,
            confirmLabel: 'Aceptar',
            cancelLabel: 'Cancelar',
            showCancel: false,
            onConfirm: () => { this.closeModal(); },
            onCancel: () => { this.closeModal(); }
        };
    }

    confirm(message: string, onConfirm: () => void, title: string = 'Confirm Action', type: ModalType = 'warning', options: Partial<ModalOptions> = {}) {
        this.#modal = {
            isOpen: true,
            title,
            message,
            type,
            confirmLabel: options.confirmLabel || 'Confirmar',
            cancelLabel: options.cancelLabel || 'Cancelar',
            showCancel: true,
            onConfirm: () => {
                onConfirm();
                this.closeModal();
            },
            onCancel: () => {
                if (options.onCancel) options.onCancel();
                this.closeModal();
            }
        };
    }

    closeModal() {
        this.#modal.isOpen = false;
    }
}

export const uiStore = new UIStore();
