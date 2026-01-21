-- Create a table for public profiles
create table profiles (
  id uuid references auth.users not null primary key,
  email text,
  display_name text,
  photo_url text,
  role text default 'user',
  preferences jsonb default '{}'::jsonb,
  stats jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  last_active_at timestamp with time zone
);

-- Set up Row Level Security (RLS)
alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on profiles
  for update using (auth.uid() = id);

-- Categories Table
create table categories (
  id text primary key,
  title_latin text not null,
  title_ol_chiki text not null,
  description text,
  icon_name text,
  gradient_preset text,
  "order" int default 0,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table categories enable row level security;

-- Only admins can modify categories, everyone can read
create policy "Categories are viewable by everyone." on categories
  for select using (true);
  
-- (You would add Admin policies here later based on the 'role' in profiles)

-- Lessons Table
create table lessons (
  id text primary key,
  category_id text references categories(id),
  title_latin text not null,
  title_ol_chiki text not null,
  description text,
  content jsonb, -- Flexible content structure
  "order" int default 0,
  is_active boolean default true,
  is_premium boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table lessons enable row level security;

create policy "Lessons are viewable by everyone." on lessons
  for select using (true);

-- Banners Table
create table banners (
  id text primary key,
  title text,
  subtitle text,
  gradient_preset text,
  target_route text,
  "order" int default 0,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table banners enable row level security;
create policy "Banners are viewable by everyone." on banners for select using (true);

-- Letters Table
create table letters (
  id text primary key,
  char_ol_chiki text not null,
  transliteration_latin text,
  "order" int default 0,
  is_active boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table letters enable row level security;
create policy "Letters are viewable by everyone." on letters for select using (true);

-- Quizzes Table
create table quizzes (
  id text primary key,
  category_id text references categories(id),
  title text,
  level text default 'beginner',
  "order" int default 0,
  is_active boolean default true,
  passing_score int default 70,
  questions jsonb default '[]'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now())
);

alter table quizzes enable row level security;
create policy "Quizzes are viewable by everyone." on quizzes for select using (true);


-- Functions to handle new user signup automatically
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (new.id, new.email, new.raw_user_meta_data->>'display_name', 'user');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
