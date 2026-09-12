import { supabase } from './supabaseClient.js';

async function fetchTestData() {
  const { data, error } = await supabase
    .from('your_table') // Tên bảng được tạo
    .select('*');

  if (error) {
    console.error('Error fetching data:', error);
  } else {
    console.log('Fetched data:', data);
  }
}

fetchTestData();