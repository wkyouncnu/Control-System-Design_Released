clc; clear all; close all;

s = tf('s');
G = 1/(s*(s+1)^2);

controlSystemDesigner(G)