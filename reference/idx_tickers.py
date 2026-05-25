"""
IDX Tickers - Comprehensive List of Indonesian Stock Exchange Stocks
=====================================================================
Contains ~900 IDX stock tickers formatted for Yahoo Finance (.JK suffix)
"""

# LQ45 - 45 Most Liquid Indonesian Stocks
LQ45_TICKERS = [
    'ACES.JK', 'ADRO.JK', 'AKRA.JK', 'AMMN.JK', 'AMRT.JK',
    'ANTM.JK', 'ASII.JK', 'BBCA.JK', 'BBNI.JK', 'BBRI.JK',
    'BBTN.JK', 'BMRI.JK', 'BRPT.JK', 'BUKA.JK', 'CPIN.JK',
    'EMTK.JK', 'ESSA.JK', 'EXCL.JK', 'GGRM.JK', 'GOTO.JK',
    'HRUM.JK', 'ICBP.JK', 'INCO.JK', 'INDF.JK', 'INKP.JK',
    'INTP.JK', 'ITMG.JK', 'KLBF.JK', 'MAPI.JK', 'MDKA.JK',
    'MEDC.JK', 'MIKA.JK', 'PGAS.JK', 'PTBA.JK', 'SMGR.JK',
    'TBIG.JK', 'TINS.JK', 'TLKM.JK', 'TPIA.JK', 'UNTR.JK',
    'UNVR.JK', 'ARTO.JK', 'BRIS.JK', 'MBMA.JK', 'TOWR.JK'
]

# IDX80 - Top 80 Liquid Stocks (includes LQ45)
IDX80_TICKERS = LQ45_TICKERS + [
    'AALI.JK', 'ARNA.JK', 'BFIN.JK', 'BJBR.JK', 'BJTM.JK',
    'BMTR.JK', 'BSDE.JK', 'BTPS.JK', 'CARS.JK', 'CTRA.JK',
    'DMAS.JK', 'DSNG.JK', 'ERAA.JK', 'FILM.JK', 'GJTL.JK',
    'HEAL.JK', 'HMSP.JK', 'INDY.JK', 'JPFA.JK', 'JSMR.JK',
    'KKGI.JK', 'LPPF.JK', 'LSIP.JK', 'MNCN.JK', 'MPMX.JK',
    'MTEL.JK', 'PNLF.JK', 'PWON.JK', 'SCMA.JK', 'SIDO.JK',
    'SILO.JK', 'SMRA.JK', 'SRTG.JK', 'TAPG.JK', 'WIKA.JK'
]

# All IDX Stocks - Comprehensive list (~900 stocks)
# Organized alphabetically
ALL_IDX_TICKERS = [
    # A
    'AADI.JK', 'AALI.JK', 'AAPM.JK', 'ABBA.JK', 'ABDA.JK', 'ABMM.JK', 'ACES.JK', 
    'ACRO.JK', 'ACST.JK', 'ADES.JK', 'ADHI.JK', 'ADMF.JK', 'ADMG.JK', 'ADMR.JK', 
    'ADRO.JK', 'AGAR.JK', 'AGII.JK', 'AGRO.JK', 'AGRS.JK', 'AHAP.JK', 'AISA.JK', 
    'AKKU.JK', 'AKPI.JK', 'AKRA.JK', 'AKSI.JK', 'ALDO.JK', 'ALKA.JK', 'ALMI.JK', 
    'ALTO.JK', 'AMAG.JK', 'AMAN.JK', 'AMAR.JK', 'AMFG.JK', 'AMIN.JK', 'AMMN.JK', 
    'AMRT.JK', 'AMOR.JK', 'ANDI.JK', 'ANJT.JK', 'ANTM.JK', 'APEX.JK', 'APIC.JK', 
    'APII.JK', 'APLI.JK', 'APLN.JK', 'ARCI.JK', 'AREA.JK', 'ARGO.JK', 'ARII.JK', 
    'ARKA.JK', 'ARMY.JK', 'ARNA.JK', 'ARTA.JK', 'ARTI.JK', 'ARTO.JK', 'ASBI.JK', 
    'ASGR.JK', 'ASII.JK', 'ASJT.JK', 'ASMI.JK', 'ASPI.JK', 'ASRI.JK', 'ASRM.JK', 
    'ASSA.JK', 'ATAP.JK', 'ATIC.JK', 'AUTO.JK', 'AYLS.JK', 'BACA.JK', 'BAJA.JK',
    
    # B
    'BALI.JK', 'BANK.JK', 'BAPA.JK', 'BATA.JK', 'BAUT.JK', 'BBCA.JK', 'BBHI.JK', 
    'BBKP.JK', 'BBLD.JK', 'BBMD.JK', 'BBNI.JK', 'BBRI.JK', 'BBSI.JK', 'BBSS.JK', 
    'BBTN.JK', 'BBYB.JK', 'BCAP.JK', 'BCIC.JK', 'BCIP.JK', 'BDKR.JK', 'BDMN.JK', 
    'BEBS.JK', 'BEEF.JK', 'BEKS.JK', 'BELL.JK', 'BELI.JK', 'BESS.JK', 'BEST.JK', 
    'BFIN.JK', 'BGTG.JK', 'BHAT.JK', 'BHIT.JK', 'BIKA.JK', 'BIKE.JK', 'BIMA.JK', 
    'BINA.JK', 'BINO.JK', 'BIPI.JK', 'BIPP.JK', 'BIRD.JK', 'BISI.JK', 'BJBR.JK', 
    'BJTM.JK', 'BKDP.JK', 'BKSL.JK', 'BKSW.JK', 'BLTA.JK', 'BLTZ.JK', 'BLUE.JK', 
    'BMAS.JK', 'BMHS.JK', 'BMRI.JK', 'BMSR.JK', 'BMTR.JK', 'BNBA.JK', 'BNBR.JK', 
    'BNGA.JK', 'BNII.JK', 'BNLI.JK', 'BOBA.JK', 'BOGA.JK', 'BOLA.JK', 'BOLT.JK', 
    'BOSS.JK', 'BPFI.JK', 'BPII.JK', 'BRAM.JK', 'BRAS.JK', 'BRAU.JK', 'BREN.JK',
    'BRIS.JK', 'BRMS.JK', 'BRNA.JK', 'BRPT.JK', 'BSDE.JK', 'BSIM.JK', 'BSML.JK', 
    'BSSR.JK', 'BTEK.JK', 'BTON.JK', 'BTPN.JK', 'BTPS.JK', 'BUDI.JK', 'BUKA.JK', 
    'BUKK.JK', 'BULL.JK', 'BUMI.JK', 'BUVA.JK', 'BWPT.JK', 'BYAN.JK',
    
    # C
    'CAKK.JK', 'CAMP.JK', 'CANI.JK', 'CARE.JK', 'CARS.JK', 'CASA.JK', 'CASH.JK', 
    'CBMF.JK', 'CBPE.JK', 'CBRE.JK', 'CBUT.JK', 'CCSI.JK', 'CEKA.JK', 'CENT.JK', 
    'CFIN.JK', 'CGAS.JK', 'CHEM.JK', 'CHIP.JK', 'CINT.JK', 'CITA.JK', 'CITY.JK', 
    'CLAY.JK', 'CLEO.JK', 'CLPI.JK', 'CMNP.JK', 'CMNT.JK', 'CMPP.JK', 'CMRY.JK', 
    'CNKO.JK', 'CNTX.JK', 'COAL.JK', 'COCO.JK', 'CODE.JK', 'CPIN.JK', 'CPRI.JK', 
    'CPRO.JK', 'CSAP.JK', 'CSIS.JK', 'CSMI.JK', 'CSRA.JK', 'CTRA.JK', 'CUAN.JK', 
    'CYBR.JK',
    
    # D
    'DADA.JK', 'DART.JK', 'DAYA.JK', 'DCII.JK', 'DEAL.JK', 'DEPO.JK', 'DEWA.JK', 
    'DFAM.JK', 'DGIK.JK', 'DGNS.JK', 'DIGI.JK', 'DILD.JK', 'DIVA.JK', 'DKFT.JK', 
    'DLTA.JK', 'DMAS.JK', 'DMMX.JK', 'DNAR.JK', 'DNET.JK', 'DOID.JK', 'DPNS.JK', 
    'DRMA.JK', 'DSFI.JK', 'DSNG.JK', 'DSSA.JK', 'DUTI.JK', 'DVLA.JK', 'DWGL.JK', 
    'DYAN.JK', 'DYNA.JK',
    
    # E
    'EAST.JK', 'ECII.JK', 'EDGE.JK', 'EKAD.JK', 'ELPI.JK', 'ELSA.JK', 'ELTY.JK', 
    'EMDE.JK', 'EMTK.JK', 'ENAK.JK', 'ENRG.JK', 'ENTG.JK', 'ENZO.JK', 'EPAC.JK', 
    'EPMT.JK', 'ERAA.JK', 'ERTX.JK', 'ESIP.JK', 'ESSA.JK', 'ESTA.JK', 'ESTI.JK', 
    'EWAN.JK', 'EXCL.JK', 'EXPO.JK',
    
    # F
    'FAPA.JK', 'FAST.JK', 'FASW.JK', 'FATE.JK', 'FILM.JK', 'FIMP.JK', 'FIRE.JK', 
    'FISH.JK', 'FITT.JK', 'FLMC.JK', 'FMII.JK', 'FOOD.JK', 'FORU.JK', 'FPNI.JK', 
    'FRAU.JK', 'FREN.JK', 'FUJI.JK', 'FUTR.JK',
    
    # G
    'GAMA.JK', 'GDST.JK', 'GDYR.JK', 'GEMA.JK', 'GEMS.JK', 'GGRM.JK', 'GGRP.JK', 
    'GHON.JK', 'GJTL.JK', 'GLOB.JK', 'GLVA.JK', 'GMFI.JK', 'GMTD.JK', 'GOLD.JK', 
    'GOOD.JK', 'GOTO.JK', 'GPRA.JK', 'GPSO.JK', 'GRIA.JK', 'GRPH.JK', 'GRPM.JK', 
    'GSMF.JK', 'GTBO.JK', 'GTSI.JK', 'GWSA.JK', 'GZCO.JK',
    
    # H
    'HADE.JK', 'HAIS.JK', 'HALO.JK', 'HBAT.JK', 'HDFA.JK', 'HDIT.JK', 'HEAL.JK', 
    'HERO.JK', 'HEXA.JK', 'HITS.JK', 'HKMU.JK', 'HMSP.JK', 'HOKI.JK', 'HOME.JK', 
    'HOPE.JK', 'HORA.JK', 'HPFF.JK', 'HRME.JK', 'HRTA.JK', 'HRUM.JK', 'HULL.JK', 
    'HUMI.JK',
    
    # I
    'IBFN.JK', 'IBOS.JK', 'IBST.JK', 'ICBP.JK', 'ICON.JK', 'IDEA.JK', 'IDPR.JK', 
    'IFII.JK', 'IFSH.JK', 'IGAR.JK', 'IKBI.JK', 'IMAS.JK', 'IMJS.JK', 'IMPC.JK', 
    'INAF.JK', 'INAI.JK', 'INCF.JK', 'INCI.JK', 'INCO.JK', 'INDF.JK', 'INDR.JK', 
    'INDS.JK', 'INDX.JK', 'INDY.JK', 'INFO.JK', 'INKP.JK', 'INNE.JK', 'INOV.JK', 
    'INPC.JK', 'INPP.JK', 'INPS.JK', 'INRU.JK', 'INTA.JK', 'INTD.JK', 'INTP.JK', 
    'IPAC.JK', 'IPCC.JK', 'IPCM.JK', 'IPOL.JK', 'IPPE.JK', 'IPTV.JK', 'IRRA.JK', 
    'IRSX.JK', 'ISAP.JK', 'ISAT.JK', 'ISSP.JK', 'ITIC.JK', 'ITMG.JK',
    
    # J
    'JARR.JK', 'JAST.JK', 'JAWA.JK', 'JAYA.JK', 'JECC.JK', 'JGLE.JK', 'JIHD.JK', 
    'JKON.JK', 'JKSW.JK', 'JMAS.JK', 'JPFA.JK', 'JRPT.JK', 'JSKY.JK', 'JSMR.JK', 
    'JSPT.JK', 'JTPE.JK',
    
    # K
    'KAEF.JK', 'KARW.JK', 'KAYU.JK', 'KBAG.JK', 'KBLI.JK', 'KBLM.JK', 'KBLV.JK', 
    'KBRI.JK', 'KDSI.JK', 'KEEN.JK', 'KEJU.JK', 'KEJA.JK', 'KENN.JK', 'KETR.JK', 
    'KIAS.JK', 'KICI.JK', 'KIJA.JK', 'KINO.JK', 'KIOS.JK', 'KJEN.JK', 'KKGI.JK', 
    'KLBF.JK', 'KLED.JK', 'KMDS.JK', 'KMTR.JK', 'KOBX.JK', 'KOIN.JK', 'KONI.JK', 
    'KOPI.JK', 'KOTA.JK', 'KPAS.JK', 'KPIG.JK', 'KRAS.JK', 'KREN.JK', 'KUAS.JK', 
    'KUDA.JK',
    
    # L
    'LABA.JK', 'LAND.JK', 'LAPD.JK', 'LCGP.JK', 'LEAD.JK', 'LEBE.JK', 'LFLO.JK', 
    'LIFE.JK', 'LINK.JK', 'LION.JK', 'LMAS.JK', 'LMPI.JK', 'LMSH.JK', 'LPCK.JK', 
    'LPGI.JK', 'LPIN.JK', 'LPKR.JK', 'LPLI.JK', 'LPPF.JK', 'LPPS.JK', 'LRNA.JK', 
    'LSIP.JK', 'LTLS.JK', 'LUCK.JK', 'LUCY.JK',
    
    # M
    'MABA.JK', 'MAGP.JK', 'MAIN.JK', 'MAMI.JK', 'MANG.JK', 'MAPA.JK', 'MAPI.JK', 
    'MARK.JK', 'MASA.JK', 'MASB.JK', 'MAYA.JK', 'MBAP.JK', 'MBMA.JK', 'MBSS.JK', 
    'MBTO.JK', 'MCAS.JK', 'MCOL.JK', 'MCOR.JK', 'MDIA.JK', 'MDKA.JK', 'MDKI.JK', 
    'MDLN.JK', 'MEDC.JK', 'MEGA.JK', 'MEJA.JK', 'MENN.JK', 'MERK.JK', 'META.JK', 
    'MFIN.JK', 'MFMI.JK', 'MGNA.JK', 'MGRO.JK', 'MICE.JK', 'MIDI.JK', 'MIKA.JK', 
    'MINA.JK', 'MIRA.JK', 'MITI.JK', 'MKNT.JK', 'MKPI.JK', 'MLBI.JK', 'MLIA.JK', 
    'MLPL.JK', 'MLPT.JK', 'MMLP.JK', 'MNCN.JK', 'MOLI.JK', 'MPMX.JK', 'MPOW.JK', 
    'MPPA.JK', 'MPRO.JK', 'MRAT.JK', 'MREI.JK', 'MSIN.JK', 'MTDL.JK', 'MTEL.JK', 
    'MTFN.JK', 'MTLA.JK', 'MTPS.JK', 'MTSM.JK', 'MTWI.JK', 'MYRX.JK',
    
    # N
    'NANO.JK', 'NASA.JK', 'NASI.JK', 'NATO.JK', 'NAYZ.JK', 'NCKL.JK', 'NELY.JK', 
    'NETV.JK', 'NFCX.JK', 'NICK.JK', 'NICL.JK', 'NIKL.JK', 'NIPS.JK', 'NISP.JK', 
    'NNYA.JK', 'NOBU.JK', 'NPGF.JK', 'NRCA.JK', 'NSSS.JK', 'NUSA.JK', 'NZIA.JK',
    
    # O
    'OASA.JK', 'OBMD.JK', 'OILS.JK', 'OKAY.JK', 'OKAS.JK', 'OLIV.JK', 'OMRE.JK', 
    'OPMS.JK', 'ORBR.JK',
    
    # P
    'PACK.JK', 'PADI.JK', 'PALM.JK', 'PAMG.JK', 'PANC.JK', 'PANI.JK', 'PANR.JK', 
    'PANS.JK', 'PARA.JK', 'PBRX.JK', 'PBSA.JK', 'PCAR.JK', 'PDES.JK', 'PEGE.JK', 
    'PEHA.JK', 'PEVE.JK', 'PGAS.JK', 'PGEO.JK', 'PGLI.JK', 'PGUN.JK', 'PICO.JK', 
    'PJAA.JK', 'PKPK.JK', 'PLAN.JK', 'PLAS.JK', 'PLAY.JK', 'PLIN.JK', 'PNBN.JK', 
    'PNBS.JK', 'PNGO.JK', 'PNIN.JK', 'PNLF.JK', 'PNSE.JK', 'POFI.JK', 'POLA.JK', 
    'POLI.JK', 'POLL.JK', 'POLY.JK', 'POOL.JK', 'PORT.JK', 'POSA.JK', 'PPGL.JK', 
    'PPRE.JK', 'PPRO.JK', 'PRAS.JK', 'PRDA.JK', 'PRIM.JK', 'PRIS.JK', 'PRJU.JK', 
    'PSAB.JK', 'PSDN.JK', 'PSGO.JK', 'PSKT.JK', 'PSSI.JK', 'PTBA.JK', 'PTDU.JK', 
    'PTIS.JK', 'PTMP.JK', 'PTPP.JK', 'PTPW.JK', 'PTRO.JK', 'PTSN.JK', 'PTSP.JK', 
    'PUDP.JK', 'PURA.JK', 'PURE.JK', 'PURI.JK', 'PWON.JK', 'PYFA.JK',
    
    # Q-R
    'RAAM.JK', 'RAJA.JK', 'RALS.JK', 'RANC.JK', 'RBMS.JK', 'RCCC.JK', 'RDTX.JK', 
    'REAL.JK', 'RELF.JK', 'RGAS.JK', 'RICY.JK', 'RIGS.JK', 'RISE.JK', 'RMBA.JK', 
    'RMKE.JK', 'RMKO.JK', 'ROCK.JK', 'RODA.JK', 'RONY.JK', 'ROTI.JK', 'RSGK.JK', 
    'RUIS.JK', 'RUNS.JK',
    
    # S
    'SAFE.JK', 'SAGE.JK', 'SAFA.JK', 'SAIP.JK', 'SAME.JK', 'SAMF.JK', 'SAPX.JK', 
    'SATU.JK', 'SBAT.JK', 'SBMA.JK', 'SCBD.JK', 'SCCO.JK', 'SCMA.JK', 'SCNP.JK', 
    'SCPI.JK', 'SDMU.JK', 'SDPC.JK', 'SDRA.JK', 'SEMA.JK', 'SFAN.JK', 'SGER.JK', 
    'SGRO.JK', 'SHID.JK', 'SHIP.JK', 'SICO.JK', 'SIDO.JK', 'SILO.JK', 'SIMA.JK', 
    'SIMP.JK', 'SINI.JK', 'SIPD.JK', 'SKBM.JK', 'SKLT.JK', 'SKRN.JK', 'SKYB.JK', 
    'SLIS.JK', 'SMAR.JK', 'SMBR.JK', 'SMCB.JK', 'SMDM.JK', 'SMDR.JK', 'SMGR.JK', 
    'SMKL.JK', 'SMKM.JK', 'SMMA.JK', 'SMMT.JK', 'SMRA.JK', 'SMRU.JK', 'SMSM.JK', 
    'SNLK.JK', 'SOCI.JK', 'SOFA.JK', 'SOHO.JK', 'SONA.JK', 'SOUL.JK', 'SOTS.JK', 
    'SPMA.JK', 'SPTO.JK', 'SQMI.JK', 'SRAJ.JK', 'SRIL.JK', 'SRSN.JK', 'SRTG.JK', 
    'SSIA.JK', 'SSMS.JK', 'SSTM.JK', 'STAR.JK', 'STTP.JK', 'SUGI.JK', 'SULI.JK', 
    'SUPR.JK', 'SURE.JK', 'SWAT.JK',
    
    # T
    'TAIS.JK', 'TAMA.JK', 'TAPG.JK', 'TARA.JK', 'TARI.JK', 'TAXI.JK', 'TAYB.JK', 
    'TAYS.JK', 'TBIG.JK', 'TBLA.JK', 'TBMS.JK', 'TCID.JK', 'TCPI.JK', 'TEBE.JK', 
    'TECH.JK', 'TELE.JK', 'TFAS.JK', 'TFCO.JK', 'TGKA.JK', 'TGRA.JK', 'TIFA.JK', 
    'TINS.JK', 'TIRA.JK', 'TIRT.JK', 'TLKM.JK', 'TMPO.JK', 'TOBA.JK', 'TOOL.JK', 
    'TOPS.JK', 'TOTL.JK', 'TOWN.JK', 'TOWR.JK', 'TPIA.JK', 'TPMA.JK', 'TRAM.JK', 
    'TRIL.JK', 'TRIM.JK', 'TRIN.JK', 'TRIO.JK', 'TRIS.JK', 'TRJA.JK', 'TRST.JK', 
    'TRUE.JK', 'TRUK.JK', 'TRUS.JK', 'TSPC.JK', 'TURI.JK', 'UCID.JK', 'UDOM.JK',
    
    # U
    'UFOE.JK', 'UGAR.JK', 'UICI.JK', 'ULTJ.JK', 'UNIC.JK', 'UNIQ.JK', 'UNIT.JK', 
    'UNSP.JK', 'UNTR.JK', 'UNVR.JK', 'URBN.JK',
    
    # V-W
    'VICI.JK', 'VICO.JK', 'VINS.JK', 'VIVA.JK', 'VOKS.JK', 'VRNA.JK', 'WAPO.JK', 
    'WEGE.JK', 'WEHA.JK', 'WGSH.JK', 'WICO.JK', 'WIFI.JK', 'WIIM.JK', 'WIKA.JK', 
    'WMPP.JK', 'WMUU.JK', 'WOOD.JK', 'WOWS.JK', 'WSBP.JK', 'WSKT.JK', 'WTON.JK',
    
    # X-Y-Z
    'XBIO.JK', 'XCID.JK', 'YELO.JK', 'YONG.JK', 'YPAS.JK', 'YULE.JK', 'ZBRA.JK', 
    'ZINC.JK', 'ZONE.JK', 'ZYRX.JK'
]

# Remove duplicates and sort
ALL_IDX_TICKERS = sorted(list(set(ALL_IDX_TICKERS)))


def get_ticker_universe(universe: str = 'lq45') -> list:
    """
    Get list of tickers based on universe selection.
    
    Parameters:
    -----------
    universe : str
        'lq45' - LQ45 stocks (45 most liquid)
        'idx80' - IDX80 stocks (80 most liquid)
        'all' - All IDX stocks (~900)
    
    Returns:
    --------
    List of ticker symbols with .JK suffix
    """
    universe = universe.lower()
    
    if universe == 'lq45':
        return LQ45_TICKERS
    elif universe == 'idx80':
        return IDX80_TICKERS
    elif universe == 'all':
        return ALL_IDX_TICKERS
    else:
        raise ValueError(f"Unknown universe: {universe}. Use 'lq45', 'idx80', or 'all'")


if __name__ == "__main__":
    print(f"LQ45 Tickers: {len(LQ45_TICKERS)}")
    print(f"IDX80 Tickers: {len(IDX80_TICKERS)}")
    print(f"All IDX Tickers: {len(ALL_IDX_TICKERS)}")
