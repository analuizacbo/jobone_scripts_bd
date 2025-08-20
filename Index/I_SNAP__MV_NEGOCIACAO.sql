--------------------------------------------------------
--  DDL for Index I_SNAP$_MV_NEGOCIACAO
--------------------------------------------------------

  CREATE UNIQUE INDEX "I_SNAP$_MV_NEGOCIACAO" ON "MV_NEGOCIACAO" (SYS_OP_MAP_NONNULL("ORDEM_SERVICO_ID"), SYS_OP_MAP_NONNULL("NUM_REFACAO")) 
  ;
