#!/bin/bash

pushd wrf
ln -sf $WPSROOT/ungrib/Variable_Tables/Vtable.GFS Vtable
$WPSROOT/link_grib.csh ./input/*

ungrib.exe
metgrid.exe