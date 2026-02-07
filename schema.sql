-- =====================================================
-- SUPER CAR GAME - DATABASE SCHEMA
-- Multiplayer Racing Game with Supabase
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLES
-- =====================================================

-- Players Table
CREATE TABLE players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    avatar_url TEXT,
    total_races INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    best_lap_time DECIMAL(10, 3),
    total_points INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    experience_points INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 1000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_online BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT,
    CONSTRAINT username_length CHECK (char_length(username) >= 3),
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Player Cars Table (Garage)
CREATE TABLE player_cars (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    car_model VARCHAR(100) NOT NULL,
    car_color VARCHAR(50) DEFAULT 'red',
    speed_stat INTEGER DEFAULT 50 CHECK (speed_stat BETWEEN 0 AND 100),
    acceleration_stat INTEGER DEFAULT 50 CHECK (acceleration_stat BETWEEN 0 AND 100),
    handling_stat INTEGER DEFAULT 50 CHECK (handling_stat BETWEEN 0 AND 100),
    is_selected BOOLEAN DEFAULT FALSE,
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    upgrade_level INTEGER DEFAULT 1,
    UNIQUE(player_id, car_model)
);

-- Lobbies Table
CREATE TABLE lobbies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lobby_name VARCHAR(100) NOT NULL,
    host_player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    max_players INTEGER DEFAULT 4 CHECK (max_players BETWEEN 2 AND 8),
    current_players INTEGER DEFAULT 1,
    track_name VARCHAR(100) NOT NULL,
    game_mode VARCHAR(50) DEFAULT 'race' CHECK (game_mode IN ('race', 'time_trial', 'elimination', 'drift')),
    status VARCHAR(20) DEFAULT 'waiting' CHECK (status IN ('waiting', 'starting', 'in_progress', 'finished', 'cancelled')),
    is_private BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    settings JSONB DEFAULT '{}'::jsonb
);

-- Lobby Players (Join Table)
CREATE TABLE lobby_players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lobby_id UUID NOT NULL REFERENCES lobbies(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    car_model VARCHAR(100) NOT NULL,
    car_color VARCHAR(50) DEFAULT 'red',
    is_ready BOOLEAN DEFAULT FALSE,
    position INTEGER,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(lobby_id, player_id)
);

-- Races Table
CREATE TABLE races (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lobby_id UUID NOT NULL REFERENCES lobbies(id) ON DELETE CASCADE,
    track_name VARCHAR(100) NOT NULL,
    game_mode VARCHAR(50) NOT NULL,
    total_laps INTEGER DEFAULT 3,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    finished_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'finished', 'abandoned')),
    winner_id UUID REFERENCES players(id),
    race_data JSONB DEFAULT '{}'::jsonb
);

-- Race Results Table
CREATE TABLE race_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    race_id UUID NOT NULL REFERENCES races(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    finish_time DECIMAL(10, 3),
    best_lap_time DECIMAL(10, 3),
    total_laps_completed INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    coins_earned INTEGER DEFAULT 0,
    experience_earned INTEGER DEFAULT 0,
    did_finish BOOLEAN DEFAULT TRUE,
    dnf_reason VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(race_id, player_id)
);

-- Leaderboards Table
CREATE TABLE leaderboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    track_name VARCHAR(100) NOT NULL,
    game_mode VARCHAR(50) NOT NULL,
    best_time DECIMAL(10, 3) NOT NULL,
    car_model VARCHAR(100),
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    replay_data JSONB,
    UNIQUE(player_id, track_name, game_mode)
);

-- Achievements Table
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT,
    points INTEGER DEFAULT 10,
    rarity VARCHAR(20) DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
    criteria JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Player Achievements Table
CREATE TABLE player_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress INTEGER DEFAULT 100,
    UNIQUE(player_id, achievement_id)
);

-- Friends Table
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    CHECK (player_id != friend_id),
    UNIQUE(player_id, friend_id)
);

-- Chat Messages Table
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lobby_id UUID REFERENCES lobbies(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'system', 'emote')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT message_length CHECK (char_length(message) <= 500)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Players indexes
CREATE INDEX idx_players_username ON players(username);
CREATE INDEX idx_players_email ON players(email);
CREATE INDEX idx_players_is_online ON players(is_online);
CREATE INDEX idx_players_total_points ON players(total_points DESC);

-- Lobbies indexes
CREATE INDEX idx_lobbies_status ON lobbies(status);
CREATE INDEX idx_lobbies_host_player ON lobbies(host_player_id);
CREATE INDEX idx_lobbies_created_at ON lobbies(created_at DESC);

-- Lobby Players indexes
CREATE INDEX idx_lobby_players_lobby ON lobby_players(lobby_id);
CREATE INDEX idx_lobby_players_player ON lobby_players(player_id);

-- Races indexes
CREATE INDEX idx_races_lobby ON races(lobby_id);
CREATE INDEX idx_races_started_at ON races(started_at DESC);
CREATE INDEX idx_races_winner ON races(winner_id);

-- Race Results indexes
CREATE INDEX idx_race_results_race ON race_results(race_id);
CREATE INDEX idx_race_results_player ON race_results(player_id);
CREATE INDEX idx_race_results_position ON race_results(position);

-- Leaderboards indexes
CREATE INDEX idx_leaderboards_track ON leaderboards(track_name, game_mode, best_time ASC);
CREATE INDEX idx_leaderboards_player ON leaderboards(player_id);

-- Chat Messages indexes
CREATE INDEX idx_chat_messages_lobby ON chat_messages(lobby_id, created_at DESC);

-- =====================================================
-- VIEWS
-- =====================================================

-- Player Statistics View
CREATE OR REPLACE VIEW player_stats AS
SELECT 
    p.id,
    p.username,
    p.display_name,
    p.avatar_url,
    p.total_races,
    p.total_wins,
    p.total_losses,
    p.best_lap_time,
    p.total_points,
    p.level,
    p.experience_points,
    p.coins,
    p.is_online,
    CASE 
        WHEN p.total_races > 0 THEN ROUND((p.total_wins::DECIMAL / p.total_races) * 100, 2)
        ELSE 0 
    END AS win_rate,
    COUNT(DISTINCT pa.achievement_id) AS total_achievements,
    RANK() OVER (ORDER BY p.total_points DESC) AS global_rank
FROM players p
LEFT JOIN player_achievements pa ON p.id = pa.player_id
GROUP BY p.id;

-- Active Lobbies View
CREATE OR REPLACE VIEW active_lobbies AS
SELECT 
    l.id,
    l.lobby_name,
    l.track_name,
    l.game_mode,
    l.max_players,
    l.current_players,
    l.status,
    l.is_private,
    l.created_at,
    p.username AS host_username,
    p.display_name AS host_display_name
FROM lobbies l
JOIN players p ON l.host_player_id = p.id
WHERE l.status IN ('waiting', 'starting')
ORDER BY l.created_at DESC;

-- Track Leaderboards View
CREATE OR REPLACE VIEW track_leaderboards AS
SELECT 
    l.track_name,
    l.game_mode,
    l.best_time,
    l.car_model,
    l.achieved_at,
    p.username,
    p.display_name,
    p.avatar_url,
    RANK() OVER (PARTITION BY l.track_name, l.game_mode ORDER BY l.best_time ASC) AS rank
FROM leaderboards l
JOIN players p ON l.player_id = p.id
ORDER BY l.track_name, l.game_mode, l.best_time ASC;

-- Recent Races View
CREATE OR REPLACE VIEW recent_races AS
SELECT 
    r.id AS race_id,
    r.track_name,
    r.game_mode,
    r.total_laps,
    r.started_at,
    r.finished_at,
    r.duration_seconds,
    p.username AS winner_username,
    p.display_name AS winner_display_name,
    COUNT(rr.id) AS total_racers
FROM races r
LEFT JOIN players p ON r.winner_id = p.id
LEFT JOIN race_results rr ON r.id = rr.race_id
WHERE r.status = 'finished'
GROUP BY r.id, p.username, p.display_name
ORDER BY r.finished_at DESC;

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update player statistics after race
CREATE OR REPLACE FUNCTION update_player_stats_after_race()
RETURNS TRIGGER AS $$
BEGIN
    -- Update player statistics
    UPDATE players
    SET 
        total_races = total_races + 1,
        total_wins = total_wins + CASE WHEN NEW.position = 1 THEN 1 ELSE 0 END,
        total_losses = total_losses + CASE WHEN NEW.position > 1 THEN 1 ELSE 0 END,
        best_lap_time = CASE 
            WHEN best_lap_time IS NULL THEN NEW.best_lap_time
            WHEN NEW.best_lap_time < best_lap_time THEN NEW.best_lap_time
            ELSE best_lap_time
        END,
        total_points = total_points + NEW.points_earned,
        coins = coins + NEW.coins_earned,
        experience_points = experience_points + NEW.experience_earned,
        updated_at = NOW()
    WHERE id = NEW.player_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate level from experience
CREATE OR REPLACE FUNCTION calculate_player_level()
RETURNS TRIGGER AS $$
BEGIN
    -- Simple level calculation: level = floor(sqrt(experience_points / 100)) + 1
    NEW.level = FLOOR(SQRT(NEW.experience_points / 100.0)) + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update lobby player count
CREATE OR REPLACE FUNCTION update_lobby_player_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE lobbies
        SET current_players = current_players + 1
        WHERE id = NEW.lobby_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE lobbies
        SET current_players = current_players - 1
        WHERE id = OLD.lobby_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger to update player stats after race result
CREATE TRIGGER trigger_update_player_stats
    AFTER INSERT ON race_results
    FOR EACH ROW
    EXECUTE FUNCTION update_player_stats_after_race();

-- Trigger to calculate player level
CREATE TRIGGER trigger_calculate_level
    BEFORE UPDATE OF experience_points ON players
    FOR EACH ROW
    WHEN (OLD.experience_points IS DISTINCT FROM NEW.experience_points)
    EXECUTE FUNCTION calculate_player_level();

-- Trigger to update lobby player count
CREATE TRIGGER trigger_lobby_player_count_insert
    AFTER INSERT ON lobby_players
    FOR EACH ROW
    EXECUTE FUNCTION update_lobby_player_count();

CREATE TRIGGER trigger_lobby_player_count_delete
    AFTER DELETE ON lobby_players
    FOR EACH ROW
    EXECUTE FUNCTION update_lobby_player_count();

-- Trigger to update updated_at timestamp
CREATE TRIGGER trigger_players_updated_at
    BEFORE UPDATE ON players
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_cars ENABLE ROW LEVEL SECURITY;
ALTER TABLE lobbies ENABLE ROW LEVEL SECURITY;
ALTER TABLE lobby_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE races ENABLE ROW LEVEL SECURITY;
ALTER TABLE race_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Players policies
CREATE POLICY "Players can view all profiles" ON players
    FOR SELECT USING (true);

CREATE POLICY "Players can update own profile" ON players
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Anyone can create a player" ON players
    FOR INSERT WITH CHECK (true);

-- Player Cars policies
CREATE POLICY "Players can view own cars" ON player_cars
    FOR SELECT USING (auth.uid() = player_id);

CREATE POLICY "Players can manage own cars" ON player_cars
    FOR ALL USING (auth.uid() = player_id);

-- Lobbies policies
CREATE POLICY "Anyone can view public lobbies" ON lobbies
    FOR SELECT USING (is_private = false OR auth.uid() = host_player_id);

CREATE POLICY "Players can create lobbies" ON lobbies
    FOR INSERT WITH CHECK (auth.uid() = host_player_id);

CREATE POLICY "Host can update own lobby" ON lobbies
    FOR UPDATE USING (auth.uid() = host_player_id);

CREATE POLICY "Host can delete own lobby" ON lobbies
    FOR DELETE USING (auth.uid() = host_player_id);

-- Lobby Players policies
CREATE POLICY "Players can view lobby members" ON lobby_players
    FOR SELECT USING (true);

CREATE POLICY "Players can join lobbies" ON lobby_players
    FOR INSERT WITH CHECK (auth.uid() = player_id);

CREATE POLICY "Players can leave lobbies" ON lobby_players
    FOR DELETE USING (auth.uid() = player_id);

-- Race Results policies
CREATE POLICY "Anyone can view race results" ON race_results
    FOR SELECT USING (true);

CREATE POLICY "System can insert race results" ON race_results
    FOR INSERT WITH CHECK (true);

-- Leaderboards policies
CREATE POLICY "Anyone can view leaderboards" ON leaderboards
    FOR SELECT USING (true);

CREATE POLICY "System can manage leaderboards" ON leaderboards
    FOR ALL USING (true);

-- Achievements policies
CREATE POLICY "Anyone can view achievements" ON achievements
    FOR SELECT USING (true);

-- Player Achievements policies
CREATE POLICY "Players can view all unlocked achievements" ON player_achievements
    FOR SELECT USING (true);

CREATE POLICY "System can unlock achievements" ON player_achievements
    FOR INSERT WITH CHECK (true);

-- Friendships policies
CREATE POLICY "Players can view own friendships" ON friendships
    FOR SELECT USING (auth.uid() = player_id OR auth.uid() = friend_id);

CREATE POLICY "Players can manage own friendships" ON friendships
    FOR ALL USING (auth.uid() = player_id);

-- Chat Messages policies
CREATE POLICY "Players can view lobby chat" ON chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM lobby_players
            WHERE lobby_id = chat_messages.lobby_id
            AND player_id = auth.uid()
        )
    );

CREATE POLICY "Players can send messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = player_id);

-- =====================================================
-- SEED DATA
-- =====================================================

-- Insert default achievements
INSERT INTO achievements (name, description, icon_url, points, rarity, criteria) VALUES
('First Race', 'Complete your first race', NULL, 10, 'common', '{"races_completed": 1}'::jsonb),
('Speed Demon', 'Win 10 races', NULL, 50, 'rare', '{"races_won": 10}'::jsonb),
('Track Master', 'Set a record on any track', NULL, 100, 'epic', '{"leaderboard_records": 1}'::jsonb),
('Millionaire', 'Earn 1,000,000 coins', NULL, 200, 'legendary', '{"total_coins": 1000000}'::jsonb),
('Social Butterfly', 'Add 10 friends', NULL, 30, 'common', '{"friends_count": 10}'::jsonb),
('Podium Finish', 'Finish in top 3 positions 50 times', NULL, 75, 'rare', '{"top_3_finishes": 50}'::jsonb),
('Perfect Lap', 'Complete a lap without hitting any obstacles', NULL, 40, 'rare', '{"perfect_laps": 1}'::jsonb),
('Marathon Racer', 'Complete 100 races', NULL, 150, 'epic', '{"races_completed": 100}'::jsonb);

-- =====================================================
-- REALTIME SUBSCRIPTIONS
-- =====================================================

-- Enable realtime for multiplayer features
ALTER PUBLICATION supabase_realtime ADD TABLE lobbies;
ALTER PUBLICATION supabase_realtime ADD TABLE lobby_players;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE players;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE players IS 'Stores player account information and statistics';
COMMENT ON TABLE player_cars IS 'Stores cars owned by each player';
COMMENT ON TABLE lobbies IS 'Stores game lobbies for multiplayer races';
COMMENT ON TABLE lobby_players IS 'Junction table for players in lobbies';
COMMENT ON TABLE races IS 'Stores completed race information';
COMMENT ON TABLE race_results IS 'Stores individual player results for each race';
COMMENT ON TABLE leaderboards IS 'Stores best times for each track';
COMMENT ON TABLE achievements IS 'Stores available achievements';
COMMENT ON TABLE player_achievements IS 'Tracks which achievements players have unlocked';
COMMENT ON TABLE friendships IS 'Stores friend relationships between players';
COMMENT ON TABLE chat_messages IS 'Stores chat messages in lobbies';
