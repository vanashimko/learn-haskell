{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses #-}

module KMeans where

import Data.List
import qualified Data.Map as M

class Ord v => Vector v where
    distance :: v -> v -> Double
    centroid :: [v] -> v

instance Vector (Double, Double) where
    distance (a, b) (c, d) = sqrt $ (c - a)**2 + (d - b)**2
    centroid lst =  let (u, v) = foldr (\(a, b) (c, d) -> (a+c, b+d)) (0.0, 0.0) lst
                        n = fromIntegral $ length lst
                    in (u/n, v/n)

class Vector v => Vectorizable e v where
    toVector :: e -> v

instance Vectorizable (Double, Double) (Double, Double) where
    toVector = id

clusterAssignmentPhase :: (Vector v, Vectorizable e v) => [v] -> [e] -> M.Map v [e]
clusterAssignmentPhase centroids points =
    let initialMap = M.fromList $ zip centroids (repeat [])
    in foldr    (\p m ->    let chosenCentroid = minimumBy  (\x y -> compare (distance x $ toVector p) (distance y $ toVector p) ) 
                                                            centroids
                            in M.adjust (p:) chosenCentroid m)
                initialMap points

newCentroidPhase :: (Vector v, Vectorizable e v) => M.Map v [e] -> [(v, v)]
newCentroidPhase = M.toList . fmap (centroid . map toVector)

shouldStop :: (Vector v) => [(v, v)] -> Double -> Bool
shouldStop centroids threshold = foldr (\(x, y) s -> s + distance x y) 0.0 centroids < threshold

kMeans :: (Vector v, Vectorizable e v) => (Int -> [e] -> [v]) -> Int -> [e] -> Double -> ([v], Int)
kMeans initializer k points = kMeans' (initializer k points) points 1

kMeans' :: (Vector v, Vectorizable e v) => [v] -> [e] -> Int -> Double -> ([v], Int)
kMeans' centroids points iteration threshold = 
    let assignments = clusterAssignmentPhase centroids points
        oldNewCentroids = newCentroidPhase assignments
        newCentroids = map snd oldNewCentroids
    in  if shouldStop oldNewCentroids threshold
        then (newCentroids, iteration)
        else kMeans' newCentroids points (succ iteration) threshold

initializeSimple :: Int -> [e] -> [(Double, Double)]
initializeSimple 0 _ = []
initializeSimple n v = (fromIntegral n, fromIntegral n) : initializeSimple (n-1) v