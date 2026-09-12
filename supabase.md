# Connecting to Supabase

This document provides a step-by-step guide for connecting to Supabase for use in the InventoryAssistant project.

## Prerequisites

Before you begin, ensure you have the following:
- A Supabase account. You can sign up at [https://supabase.com/](https://supabase.com/).
- The Project URL and API Key for your Supabase project.
- Node.js installed on your development environment.

## Steps to Connect

1. **Install the Supabase Client**
   Open your terminal in the project directory and run the following command:
   ```bash
   npm install @supabase/supabase-js
   ```

2. **Locate Your Project Credentials**
   Log in to the Supabase dashboard, navigate to your project, and copy the Project URL and anon public API key from the "Settings" > "API" page.

3. **Set Environment Variables**
   Add your Supabase credentials to an `.env` file in the root of your project (if not already present):
   ```env
   SUPABASE_URL=your-project-url
   SUPABASE_ANON_KEY=your-anon-key
   ```
   Replace `your-project-url` and `your-anon-key` with the credentials from step 2.

4. **Initialize the Supabase Client**
   Use the following code to initialize the Supabase client in your project:
   ```javascript
   import { createClient } from '@supabase/supabase-js';

   const supabaseUrl = process.env.SUPABASE_URL;
   const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

   export const supabase = createClient(supabaseUrl, supabaseAnonKey);
   ```

5. **Test the Connection**
   Verify the connection by querying a sample table:
   ```javascript
   async function testConnection() {
     const { data, error } = await supabase
       .from('sample_table')
       .select('*');

     if (error) {
       console.error('Error:', error);
     } else {
       console.log('Data:', data);
     }
   }

   testConnection();
   ```

6. **Use Supabase in Your Project**
   Once connected, you can use the Supabase client to interact with your database, including performing CRUD operations, authentication, and more.

---

## Additional References

- [Supabase Documentation](https://supabase.com/docs) for detailed guides and advanced use-cases.
- If you encounter issues, check the InventoryAssistant team Slack channel for help or consult Supabase community forums.