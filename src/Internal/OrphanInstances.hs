{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Internal.OrphanInstances ( ) where

import Control.DeepSeq
import Distribution.System

-- This is needed for GHC 8.4+, due to new Cabal
#if !MIN_VERSION_base(4,11,0)
instance NFData Arch
instance NFData OS
instance NFData Platform
#endif
