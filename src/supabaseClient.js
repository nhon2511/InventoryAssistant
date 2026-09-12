import { createClient } from "@supabase/supabase-js";
import { SUPABASE_URL, SUPABASE_KEY } from "./supabaseConfig.js";

// Khởi tạo client Supabase
export const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);