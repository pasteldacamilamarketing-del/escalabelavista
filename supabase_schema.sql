-- ============================================================
-- SCHEMA — Pastel da Camila Escala
-- Rodar no SQL Editor do Supabase
-- ============================================================

-- ── TABELA: dias da escala ──
-- Cada linha = um dia com todos os turnos em JSON
CREATE TABLE IF NOT EXISTS escala_dias (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  date        date NOT NULL UNIQUE,          -- '2026-04-01'
  wd          text NOT NULL,                 -- 'Qua'
  js_day      integer NOT NULL,              -- 0=Dom ... 6=Sab
  manha       jsonb NOT NULL DEFAULT '[]',   -- [{id,role,person,obs,status,...}]
  noite       jsonb NOT NULL DEFAULT '[]',
  updated_at  timestamptz DEFAULT now()
);

-- Index para busca rápida por data
CREATE INDEX IF NOT EXISTS idx_escala_date ON escala_dias(date);

-- ── TABELA: histórico de alterações ──
CREATE TABLE IF NOT EXISTS escala_historico (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at  timestamptz DEFAULT now(),
  editor      text NOT NULL,                 -- 'Admin' ou 'Vitória'
  pessoa      text NOT NULL,
  antes       text,
  depois      text,
  motivo      text NOT NULL,
  date_ref    date                           -- data do dia alterado
);

-- Index para listar histórico por data
CREATE INDEX IF NOT EXISTS idx_hist_date ON escala_historico(date_ref);
CREATE INDEX IF NOT EXISTS idx_hist_created ON escala_historico(created_at DESC);

-- ── ROW LEVEL SECURITY ──
-- Leitura pública (todo mundo vê a escala)
ALTER TABLE escala_dias ENABLE ROW LEVEL SECURITY;
ALTER TABLE escala_historico ENABLE ROW LEVEL SECURITY;

-- Qualquer um pode ler
CREATE POLICY "leitura_publica_escala"
  ON escala_dias FOR SELECT
  USING (true);

CREATE POLICY "leitura_publica_historico"
  ON escala_historico FOR SELECT
  USING (true);

-- Escrita só com chave anon (frontend valida login manualmente)
-- Por ora liberar insert/update com anon key (o login é feito no frontend)
CREATE POLICY "escrita_anon_escala"
  ON escala_dias FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "escrita_anon_historico"
  ON escala_historico FOR ALL
  USING (true)
  WITH CHECK (true);

-- ── FUNÇÃO: atualiza updated_at automaticamente ──
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_escala_updated
  BEFORE UPDATE ON escala_dias
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

