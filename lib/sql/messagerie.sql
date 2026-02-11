-- ===============================================
-- 💬 SAME SHOP - MESSAGERIE 4 CANAUX
-- ===============================================
-- Canaux: commande, enchere, fournisseur, livraison

-- ===============================================
-- 1) CONVERSATIONS
-- ===============================================
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canal TEXT NOT NULL CHECK (canal IN ('commande', 'enchere', 'fournisseur', 'livraison')),
  ref_id TEXT NOT NULL,
  participant_a UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  participant_b UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titre TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_conversation UNIQUE (canal, ref_id)
);

CREATE INDEX IF NOT EXISTS idx_conversations_participant_a ON conversations(participant_a);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_b ON conversations(participant_b);
CREATE INDEX IF NOT EXISTS idx_conversations_canal_ref ON conversations(canal, ref_id);

-- ===============================================
-- 2) MESSAGES
-- ===============================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  expediteur_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contenu TEXT NOT NULL,
  lu BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);

-- ===============================================
-- 3) RLS
-- ===============================================
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own conversations" ON conversations
FOR SELECT USING (
  auth.uid() = participant_a OR auth.uid() = participant_b
);

CREATE POLICY "Users create conversations" ON conversations
FOR INSERT WITH CHECK (
  auth.uid() = participant_a OR auth.uid() = participant_b
);

CREATE POLICY "Users update own conversations" ON conversations
FOR UPDATE USING (
  auth.uid() = participant_a OR auth.uid() = participant_b
);

CREATE POLICY "Users see messages in own conversations" ON messages
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = conversation_id
      AND (c.participant_a = auth.uid() OR c.participant_b = auth.uid())
  )
);

CREATE POLICY "Users insert messages in own conversations" ON messages
FOR INSERT WITH CHECK (
  auth.uid() = expediteur_id
  AND EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = conversation_id
      AND (c.participant_a = auth.uid() OR c.participant_b = auth.uid())
  )
);

CREATE POLICY "Users update read status" ON messages
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM conversations c
    WHERE c.id = conversation_id
      AND (c.participant_a = auth.uid() OR c.participant_b = auth.uid())
  )
);
