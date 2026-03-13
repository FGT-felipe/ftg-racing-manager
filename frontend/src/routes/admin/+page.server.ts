import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';

const ADMIN_PASSWORD = "ftgadmin2026";

export const actions: Actions = {
    login: async ({ request }) => {
        const data = await request.formData();
        const password = data.get('password');

        if (password === ADMIN_PASSWORD) {
            return { success: true };
        }

        return fail(401, {
            error: "Invalid Admin Password"
        });
    }
};
