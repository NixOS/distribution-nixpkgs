module Distribution.Nixpkgs.PackageMap
  ( PackageMap, readNixpkgPackageMap
  , readNixpkgPackageMapWithArgs
  , resolve
  ) where

import qualified Data.Aeson as JSON
import qualified Data.ByteString.Lazy as LBS
import Data.Function
import Data.List as List
import Data.List.Split
import qualified Data.Map.Strict as Map
import Data.Map.Strict ( Map )
import Data.Maybe
import Data.Set ( Set )
import qualified Data.Set as Set
import Distribution.Text
import Language.Nix
import System.Process
import Control.Lens

type PackageMap = Map Identifier (Set Path)

readNixpkgPackageMap :: FilePath -> Maybe Path -> IO PackageMap
readNixpkgPackageMap nixpkgs attrpath = readNixpkgPackageMapWithArgs nixpkgs attrpath Map.empty

readNixpkgPackageMapWithArgs :: FilePath -> Maybe Path -> Map String String -> IO PackageMap
readNixpkgPackageMapWithArgs nixpkgs attrpath args = fmap identifierSet2PackageMap (readNixpkgSet nixpkgs attrpath args)

readNixpkgSet :: FilePath -> Maybe Path -> Map String String -> IO (Set String)
readNixpkgSet nixpkgs attrpath args = do
  let extraArgs = maybe [] (\p -> ["-A", display p]) attrpath ++ concatMap (\(k,v) -> ["--arg", k, v]) (Map.toList args)
  (_, Just h, _, _) <- createProcess (proc "nix-env" (["-qaP", "--json", "-f", nixpkgs] ++ extraArgs))
                       { std_out = CreatePipe, env = Nothing }  -- TODO: ensure that overrides don't screw up our results
  buf <- LBS.hGetContents h
  let pkgmap :: Either String (Map String JSON.Object)
      pkgmap = JSON.eitherDecode buf
  either fail (return . Map.keysSet) pkgmap

identifierSet2PackageMap :: Set String -> PackageMap
identifierSet2PackageMap pkgset = foldr (uncurry insertIdentifier) Map.empty pkglist
  where
    pkglist :: [(Identifier, Path)]
    pkglist = mapMaybe parsePackage (Set.toList pkgset)

    insertIdentifier :: Identifier -> Path -> PackageMap -> PackageMap
    insertIdentifier i = Map.insertWith Set.union i . Set.singleton

parsePackage :: String -> Maybe (Identifier, Path)
parsePackage x | null x                 = error "Distribution.Nixpkgs.PackageMap.parsepackage: empty string is no valid identifier"
               | xs <- splitOn "." x    = if needsQuoting (head xs)
                                             then Nothing
                                             else Just (ident # last xs, path # map (review ident) xs)

resolve :: PackageMap -> Identifier -> Maybe Binding
resolve nixpkgs i = case Map.lookup i nixpkgs of
                      Nothing -> Nothing
                      Just ps -> let p = chooseShortestPath (Set.toList ps)
                                 in Just $ binding # (i,p)

chooseShortestPath :: [Path] -> Path
chooseShortestPath [] = error "chooseShortestPath: called with empty list argument"
chooseShortestPath ps = minimumBy (on compare (view (path . to length))) ps
