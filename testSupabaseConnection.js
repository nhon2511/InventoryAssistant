import { supabase } from './src/supabaseClient.js';

(async () => {
  try {
    const { data, error } = await supabase.from('your_table').select();
    if (error) throw error;

    console.log('Dữ liệu từ Supabase:', data);
  } catch (err) {
    console.error('Lỗi khi kết nối Supabase:', err.message);
  }
})();