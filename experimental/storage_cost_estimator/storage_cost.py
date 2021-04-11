#!/home/linuxuser/anaconda3/bin/python3

import argparse
import pandas as pd
from pandas import ExcelWriter
from pandas import ExcelFile


blob_storage_capacity_limit_TiB = 5120
hpc_cache_max_capacity_TiB = 48.0
hpc_cache_max_throughput_GBps = 8.0
hpc_cache_write_throughput_percent = 0.4
anf_max_write_bw_GBps = 1.5
ROUNDOFF_ADJUST_FACTOR = 1.15
IOPS_transfer_size_KB = 4.0

excel_file='./vm_storage_limits_costs.xlsx'


def read_excel(excel_file):

   disk_limits_sheet = pd.read_excel(excel_file, skiprows=3, sheet_name='Disks limits')
   disk_limits_sheet_dropna = disk_limits_sheet.dropna(how='all')
   vm_limits_sheet = pd.read_excel(excel_file, skiprows=4, sheet_name='VM limits')
   vm_limits_sheet_dropna = vm_limits_sheet.dropna(how='all')
   anf_sheet = pd.read_excel(excel_file, skiprows=4, sheet_name='anf')
   anf_sheet_dropna = anf_sheet.dropna(how='all')
   blob_sheet = pd.read_excel(excel_file, skiprows=7, sheet_name='blob')
   blob_sheet_dropna = blob_sheet.dropna(how='all')
   hpc_cache_sheet = pd.read_excel(excel_file, skiprows=4, sheet_name='hpc_cache')
   hpc_cache_sheet_dropna = hpc_cache_sheet.dropna(how='all')

   disk_name_l = list(disk_limits_sheet_dropna['Name'])
   disk_size_TiB_l = list(disk_limits_sheet_dropna['Size (TiB)'])
   disk_price_per_month_l = list(disk_limits_sheet_dropna['Price per month'])
   disk_iops_l = list(disk_limits_sheet_dropna['IOPS per disk'])
   disk_throughput_MBps_l = list(disk_limits_sheet_dropna['Throughput per disk (MB/s)'])

   vm_name_l = list(vm_limits_sheet_dropna['Size'])
   vm_vcpu_l = list(vm_limits_sheet_dropna['vCPU'])
   vm_mem_GiB_l = list(vm_limits_sheet_dropna['Memory: GiB'])
   vm_tmp_storage_GiB_l = list(vm_limits_sheet_dropna['Temp storage (SSD) GiB'])
   vm_max_num_data_disks_l = list(vm_limits_sheet_dropna['Max data disks'])
   vm_max_cached_tmp_storage_throughput_MBps_l = list(vm_limits_sheet_dropna['Max cached and temp storage throughput: MBps'])
   vm_max_tmp_storage_read_throughput_MBps_l = list(vm_limits_sheet_dropna['Max temp storage read throughput: MBps'])
   vm_max_tmp_storage_write_throughput_MBps_l = list(vm_limits_sheet_dropna['Max temp storage write throughput: MBps'])
   vm_max_tmp_storage_iops_l = list(vm_limits_sheet_dropna['Max cached and temp storage IOPS'])
   vm_max_uncached_disk_throughput_MBps_l = list(vm_limits_sheet_dropna['Max uncached disk throughput: MBps'])
   vm_max_uncached_disk_iops_l = list(vm_limits_sheet_dropna['Max uncached disk IOPS'])
   vm_network_bw_Mbps_l = list(vm_limits_sheet_dropna['Expected Network bandwidth (Mbps)'])
   vm_cost_per_month_l = list(vm_limits_sheet_dropna['cost/month PAYGO'])

   anf_service_level_l = list(anf_sheet_dropna['Service level'])
   anf_per_GiB_per_hr_l = list(anf_sheet_dropna['per_GiB_per_hour'])
   anf_MBps_per_TiB_l = list(anf_sheet_dropna['MBps_per_TiB'])
   anf_iops_per_TiB_l = list(anf_sheet_dropna['IOPS_per_TiB'])

   blob_tier_l = list(blob_sheet_dropna['Tier'])
   blob_egress_Gbps_l = list(blob_sheet_dropna['egress_Gbps'])
   blob_ingress_Gbps_l = list(blob_sheet_dropna['ingress_Gbps'])
   blob_cost_per_TiB_l = list(blob_sheet_dropna['cost_per_TiB'])
   blob_write_cost_per_10k_ops_l = list(blob_sheet_dropna['write_cost_per_10k_ops'])
   blob_read_cost_per_10k_ops_l = list(blob_sheet_dropna['read_cost_per_10k_ops'])

   hpc_cache_throughput_GBps_l = list(hpc_cache_sheet_dropna['Throughput_GBps'])
   hpc_cache_capacity_small_TiB_l = list(hpc_cache_sheet_dropna['Capacity_small_TiB'])
   hpc_cache_capacity_medium_TiB_l = list(hpc_cache_sheet_dropna['Capacity_medium_TiB'])
   hpc_cache_capacity_large_TiB_l = list(hpc_cache_sheet_dropna['Capacity_large_TiB'])
   hpc_cache_cost_small_per_month_l = list(hpc_cache_sheet_dropna['cost_small_per_month'])
   hpc_cache_cost_medium_per_month_l = list(hpc_cache_sheet_dropna['cost_medium_per_month'])
   hpc_cache_cost_large_per_month_l = list(hpc_cache_sheet_dropna['cost_large_per_month'])

   return(disk_name_l,disk_size_TiB_l,disk_price_per_month_l,disk_iops_l,disk_throughput_MBps_l,vm_name_l,vm_vcpu_l,vm_mem_GiB_l,vm_tmp_storage_GiB_l,vm_max_num_data_disks_l,vm_max_cached_tmp_storage_throughput_MBps_l,vm_max_tmp_storage_read_throughput_MBps_l,vm_max_tmp_storage_write_throughput_MBps_l,vm_max_tmp_storage_iops_l,vm_max_uncached_disk_throughput_MBps_l,vm_max_uncached_disk_iops_l,vm_network_bw_Mbps_l,vm_cost_per_month_l,anf_service_level_l,anf_per_GiB_per_hr_l,anf_MBps_per_TiB_l,anf_iops_per_TiB_l,blob_tier_l,blob_egress_Gbps_l,blob_ingress_Gbps_l,blob_cost_per_TiB_l,blob_write_cost_per_10k_ops_l,blob_read_cost_per_10k_ops_l,hpc_cache_throughput_GBps_l,hpc_cache_capacity_small_TiB_l,hpc_cache_capacity_medium_TiB_l,hpc_cache_capacity_large_TiB_l,hpc_cache_cost_small_per_month_l,hpc_cache_cost_medium_per_month_l,hpc_cache_cost_large_per_month_l)


def nfs_disk(all_d, vm_name_l, vm_max_uncached_disk_throughput_MBps_l,disk_name_l,disk_throughput_MBps_l,vm_max_num_data_disks_l,disk_size_TiB_l,vm_cost_per_month_l,disk_price_per_month_l,vm_network_bw_Mbps_l, disk_iops_l, vm_max_uncached_disk_iops_l):

   nfs_disk_d = {}
   for v_i, vm_name in enumerate(vm_name_l):
#       print(v_i,vm_name)
       if pd.isna(vm_max_uncached_disk_throughput_MBps_l[v_i]) or target_performance_GBps > min(vm_network_bw_Mbps_l[v_i]/8.0,vm_max_uncached_disk_throughput_MBps_l[v_i]) / 1000.0:
          continue
       for d_i, disk_name in enumerate(disk_name_l):
#           print(d_i,disk_name)
           if target_capacity_TiB > vm_max_num_data_disks_l[d_i] * disk_size_TiB_l[d_i]:
              continue
           min_num_disk_target_performance = target_performance_GBps / (disk_throughput_MBps_l[d_i] / 1000.0)
           min_num_disk_target_capacity = target_capacity_TiB / disk_size_TiB_l[d_i]
           num_disks_per_vm = round(max(min_num_disk_target_performance,min_num_disk_target_capacity,1.0))
           (capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops) = nfs_disk_perf_capacity(num_disks_per_vm, disk_throughput_MBps_l[d_i], disk_iops_l[d_i], disk_size_TiB_l[d_i],vm_max_uncached_disk_iops_l[v_i])
           if target_capacity_TiB > capacity_TiB * ROUNDOFF_ADJUST_FACTOR or target_performance_GBps > max(write_bw_GBps, read_bw_GBps) * ROUNDOFF_ADJUST_FACTOR:
              continue
           total_cost_per_month = vm_cost_per_month_l[v_i] + num_disks_per_vm * disk_price_per_month_l[d_i]
           nfs_disk_description = "NFS {}+{}x{}".format(vm_name, disk_name, num_disks_per_vm)
           nfs_disk_d[nfs_disk_description] = {}
           nfs_disk_d[nfs_disk_description]['total_cost_per_month'] =  total_cost_per_month
           nfs_disk_d[nfs_disk_description]['capacity_TiB'] =  capacity_TiB
           nfs_disk_d[nfs_disk_description]['write_bw_GBps'] =  write_bw_GBps
           nfs_disk_d[nfs_disk_description]['read_bw_GBps'] =  read_bw_GBps
           nfs_disk_d[nfs_disk_description]['write_iops'] =  write_iops
           nfs_disk_d[nfs_disk_description]['read_iops'] =  read_iops

   count=0
   for key, value in sorted(nfs_disk_d.items(), key=lambda item: item[1]['total_cost_per_month']):
       if count < group_report_size and not pd.isna(nfs_disk_d[key]['total_cost_per_month']):
           all_d[key] = {}
           all_d[key]['total_cost_per_month'] = value['total_cost_per_month']
           all_d[key]['capacity_TiB'] = value['capacity_TiB']
           all_d[key]['write_bw_GBps'] = value['write_bw_GBps']
           all_d[key]['read_bw_GBps'] = value['read_bw_GBps']
           all_d[key]['write_iops'] = value['write_iops']
           all_d[key]['read_iops'] = value['read_iops']
           count = count + 1


def nfs_local_ssd(all_d, vm_name_l, vm_tmp_storage_GiB_l, vm_max_tmp_storage_read_throughput_MBps_l, vm_max_tmp_storage_write_throughput_MBps_l, vm_cost_per_month_l, vm_network_bw_Mbps_l, vm_max_tmp_storage_iops_l):

   nfs_local_ssd_d = {}
   for v_i, vm_name in enumerate(vm_name_l):
#       print(v_i,vm_name)
       if pd.isna(vm_tmp_storage_GiB_l[v_i]):
          continue
       (capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops) = nfs_local_ssd_perf_capacity(vm_max_tmp_storage_read_throughput_MBps_l[v_i], vm_max_tmp_storage_write_throughput_MBps_l[v_i], vm_max_tmp_storage_iops_l[v_i], vm_tmp_storage_GiB_l[v_i], vm_network_bw_Mbps_l[v_i])
       if target_capacity_TiB > capacity_TiB * ROUNDOFF_ADJUST_FACTOR or target_performance_GBps > max(write_bw_GBps, read_bw_GBps) * ROUNDOFF_ADJUST_FACTOR:
          continue
       total_cost_per_month_local_ssd = vm_cost_per_month_l[v_i]
       nfs_description_local_ssd = "NFS {}+local_ssd".format(vm_name)
       nfs_local_ssd_d[nfs_description_local_ssd] = {}
       nfs_local_ssd_d[nfs_description_local_ssd]['total_cost_per_month'] =  total_cost_per_month_local_ssd
       nfs_local_ssd_d[nfs_description_local_ssd]['capacity_TiB'] =  capacity_TiB
       nfs_local_ssd_d[nfs_description_local_ssd]['write_bw_GBps'] =  write_bw_GBps
       nfs_local_ssd_d[nfs_description_local_ssd]['read_bw_GBps'] =  read_bw_GBps
       nfs_local_ssd_d[nfs_description_local_ssd]['write_iops'] =  write_iops
       nfs_local_ssd_d[nfs_description_local_ssd]['read_iops'] =  read_iops

   count=0
   for key, value in sorted(nfs_local_ssd_d.items(), key=lambda item: item[1]['total_cost_per_month']):
       if count < group_report_size and not pd.isna(nfs_local_ssd_d[key]['total_cost_per_month']):
          all_d[key] = {}
          all_d[key]['total_cost_per_month'] = value['total_cost_per_month']
          all_d[key]['capacity_TiB'] = value['capacity_TiB']
          all_d[key]['write_bw_GBps'] = value['write_bw_GBps']
          all_d[key]['read_bw_GBps'] = value['read_bw_GBps']
          all_d[key]['write_iops'] = value['write_iops']
          all_d[key]['read_iops'] = value['read_iops']
          count = count + 1


def nfs_disk_perf_capacity(num_disks_per_vm, disk_throughput_MBps, disk_iops, disk_size_TiB, max_iops_per_vm):

    capacity_TiB = num_disks_per_vm * disk_size_TiB
    write_bw_GBps =  num_disks_per_vm * disk_throughput_MBps / 1000.0
    read_bw_GBps = write_bw_GBps
    write_iops = min(num_disks_per_vm * disk_iops, max_iops_per_vm)
    read_iops = write_iops

    return(capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops)


def nfs_local_ssd_perf_capacity(local_ssd_read_bw_MBps, local_ssd_write_bw_MBps, local_ssd_iops, local_ssd_size_GiB, vm_network_bw_Mbps):

    capacity_TiB = local_ssd_size_GiB / 1024.0
    write_bw_GBps = local_ssd_write_bw_MBps / 1000.0
    read_bw_GBps = local_ssd_read_bw_MBps / 1000.0
    vm_max_network_iops =  vm_network_bw_Mbps / (IOPS_transfer_size_KB / 8000.0)
    write_iops = min(local_ssd_iops,vm_max_network_iops)
    read_iops = write_iops

    return(capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops)


def anf_perf_capacity(capacity_TiB, MBps_per_TiB, iops_per_TiB):

    read_bw_GBps = capacity_TiB * MBps_per_TiB / 1000.0
    write_bw_GBps = min(anf_max_write_bw_GBps,read_bw_GBps)
    write_iops = capacity_TiB * iops_per_TiB
    read_iops = write_iops

    return(capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops)


def pfs_disk_perf_capacity(total_num_vms, num_disks_per_vm, disk_throughput_MBps, disk_iops, disk_size_TiB, max_iops_per_vm):

    pfs_capacity_TiB = total_num_vms * num_disks_per_vm * disk_size_TiB
    write_bw_GBps = total_num_vms * num_disks_per_vm * disk_throughput_MBps / 1000.0
    read_bw_GBps = write_bw_GBps
    write_iops = total_num_vms * min(num_disks_per_vm * disk_iops, max_iops_per_vm)
    read_iops = write_iops

    return(pfs_capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops)


def pfs_local_ssd_perf_capacity(total_num_vms, local_ssd_read_bw_MBps, local_ssd_write_bw_MBps, local_ssd_iops, local_ssd_size_GiB, vm_network_bw_Mbps):

    pfs_capacity_TiB = total_num_vms *  local_ssd_size_GiB / 1024.0
    write_bw_GBps = total_num_vms * local_ssd_write_bw_MBps / 1000.0
    read_bw_GBps = total_num_vms * local_ssd_read_bw_MBps / 1000.0
    vm_max_network_iops =  vm_network_bw_Mbps / (IOPS_transfer_size_KB / 8000.0)
    write_iops = total_num_vms * min(local_ssd_iops,vm_max_network_iops)
    read_iops = write_iops

    return(pfs_capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops)


def pfs_disk(all_d, vm_name_l, vm_max_uncached_disk_throughput_MBps_l,disk_name_l,disk_throughput_MBps_l,vm_max_num_data_disks_l,disk_size_TiB_l,vm_cost_per_month_l,disk_price_per_month_l, disk_iops_l, vm_max_uncached_disk_iops_l):

   pfs_disk_d = {}
   for v_i, vm_name in enumerate(vm_name_l):
#       print(v_i,vm_name)
       if pd.isna(vm_max_uncached_disk_throughput_MBps_l[v_i]):
          continue
       for d_i, disk_name in enumerate(disk_name_l):
#           print(d_i,disk_name)
           max_disk_BW_MBps_per_vm = disk_throughput_MBps_l[d_i] * vm_max_num_data_disks_l[v_i]
           max_BW_MBps_per_vm = min(vm_max_uncached_disk_throughput_MBps_l[v_i],max_disk_BW_MBps_per_vm)
           min_num_vm_target_performance = target_performance_GBps / (max_BW_MBps_per_vm / 1000.0)
           min_num_vm_target_capacity = target_capacity_TiB / (disk_size_TiB_l[d_i] * vm_max_num_data_disks_l[v_i])
           min_num_disks_vm_target_capacity = (target_capacity_TiB / max(min_num_vm_target_performance,min_num_vm_target_capacity) / disk_size_TiB_l[d_i])
           min_num_disks_vm_target_performance = max_BW_MBps_per_vm / disk_throughput_MBps_l[d_i]
           num_disks_per_vm = round(max(min_num_disks_vm_target_capacity,min_num_disks_vm_target_performance,1.0))
           total_num_vms = round(max(min_num_vm_target_performance,min_num_vm_target_capacity,1.0))
           total_num_disks = total_num_vms * num_disks_per_vm
           (pfs_capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops) = pfs_disk_perf_capacity(total_num_vms, num_disks_per_vm, disk_throughput_MBps_l[d_i], disk_iops_l[d_i], disk_size_TiB_l[d_i],vm_max_uncached_disk_iops_l[v_i])
#           print(pfs_capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops)
           if target_capacity_TiB > pfs_capacity_TiB * ROUNDOFF_ADJUST_FACTOR or target_performance_GBps > max(write_bw_GBps, read_bw_GBps) * ROUNDOFF_ADJUST_FACTOR:
              continue
           total_cost_per_month = total_num_vms * vm_cost_per_month_l[v_i] + total_num_disks * disk_price_per_month_l[d_i]
           pfs_disk_description = "(PFS {}+{}x{})x{}".format(vm_name, disk_name, num_disks_per_vm,total_num_vms)
           pfs_disk_d[pfs_disk_description] = {}
           pfs_disk_d[pfs_disk_description]['total_cost_per_month'] =  total_cost_per_month
           pfs_disk_d[pfs_disk_description]['capacity_TiB'] =  pfs_capacity_TiB
           pfs_disk_d[pfs_disk_description]['write_bw_GBps'] =  write_bw_GBps
           pfs_disk_d[pfs_disk_description]['read_bw_GBps'] =  read_bw_GBps
           pfs_disk_d[pfs_disk_description]['write_iops'] =  write_iops
           pfs_disk_d[pfs_disk_description]['read_iops'] =  read_iops

   count=0
   for key, value in sorted(pfs_disk_d.items(), key=lambda item: item[1]['total_cost_per_month']):
       if count < group_report_size and not pd.isna(pfs_disk_d[key]['total_cost_per_month']):
           all_d[key] = {}
           all_d[key]['total_cost_per_month'] = value['total_cost_per_month']
           all_d[key]['capacity_TiB'] = value['capacity_TiB']
           all_d[key]['write_bw_GBps'] = value['write_bw_GBps']
           all_d[key]['read_bw_GBps'] = value['read_bw_GBps']
           all_d[key]['write_iops'] = value['write_iops']
           all_d[key]['read_iops'] = value['read_iops']
           count = count + 1


def pfs_local_ssd(all_d, vm_name_l, vm_tmp_storage_GiB_l, vm_max_tmp_storage_read_throughput_MBps_l, vm_max_tmp_storage_write_throughput_MBps_l, vm_cost_per_month_l, vm_network_bw_Mbps_l, vm_max_tmp_storage_iops_l):

   pfs_local_ssd_d = {}
   for v_i, vm_name in enumerate(vm_name_l):
#       print(v_i,vm_name)
       if not pd.isna(vm_tmp_storage_GiB_l[v_i]):
          min_num_vm_target_performance_local_ssd = max(target_performance_GBps / (min(vm_network_bw_Mbps_l[v_i]/8.0,vm_max_tmp_storage_read_throughput_MBps_l[v_i],vm_max_tmp_storage_write_throughput_MBps_l[v_i]) / 1000.0), 1.0)
          min_num_vm_target_capacity_local_ssd = max(target_capacity_TiB / (vm_tmp_storage_GiB_l[v_i]/1024.0), 1.0)
          total_num_vms_local_ssd = round(max(min_num_vm_target_performance_local_ssd,min_num_vm_target_capacity_local_ssd))
          (pfs_capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops) = pfs_local_ssd_perf_capacity(total_num_vms_local_ssd, vm_max_tmp_storage_read_throughput_MBps_l[v_i], vm_max_tmp_storage_write_throughput_MBps_l[v_i], vm_max_tmp_storage_iops_l[v_i], vm_tmp_storage_GiB_l[v_i], vm_network_bw_Mbps_l[v_i])
          if target_capacity_TiB > pfs_capacity_TiB * ROUNDOFF_ADJUST_FACTOR or target_performance_GBps > max(write_bw_GBps, read_bw_GBps) * ROUNDOFF_ADJUST_FACTOR:
             continue
          total_cost_per_month_local_ssd = total_num_vms_local_ssd * vm_cost_per_month_l[v_i]
          pfs_description_local_ssd = "(PFS {}+local_ssd)x{}".format(vm_name, total_num_vms_local_ssd)
          pfs_local_ssd_d[pfs_description_local_ssd] = {}
          pfs_local_ssd_d[pfs_description_local_ssd]['total_cost_per_month'] =  total_cost_per_month_local_ssd
          pfs_local_ssd_d[pfs_description_local_ssd]['capacity_TiB'] =  pfs_capacity_TiB
          pfs_local_ssd_d[pfs_description_local_ssd]['write_bw_GBps'] =  write_bw_GBps
          pfs_local_ssd_d[pfs_description_local_ssd]['read_bw_GBps'] =  read_bw_GBps
          pfs_local_ssd_d[pfs_description_local_ssd]['write_iops'] =  write_iops
          pfs_local_ssd_d[pfs_description_local_ssd]['read_iops'] =  read_iops

   count=0
   for key, value in sorted(pfs_local_ssd_d.items(), key=lambda item: item[1]['total_cost_per_month']):
       if count < group_report_size and not pd.isna(pfs_local_ssd_d[key]['total_cost_per_month']):
          all_d[key] = {}
          all_d[key]['total_cost_per_month'] = value['total_cost_per_month']
          all_d[key]['capacity_TiB'] = value['capacity_TiB']
          all_d[key]['write_bw_GBps'] = value['write_bw_GBps']
          all_d[key]['read_bw_GBps'] = value['read_bw_GBps']
          all_d[key]['write_iops'] = value['write_iops']
          all_d[key]['read_iops'] = value['read_iops']
          count = count + 1


def anf(all_d, anf_service_level_l, anf_per_GiB_per_hr_l, anf_MBps_per_TiB_l, anf_iops_per_TiB_l):

   anf_d = {}
   if target_capacity_TiB < 110 or target_performance_GBps < 6:
      for a_i, service_level in enumerate(anf_service_level_l):
          service_level_capacity_TiB = round(target_performance_GBps / (anf_MBps_per_TiB_l[a_i] / 1000.0))
          service_level_performance_GBps = (target_capacity_TiB * anf_MBps_per_TiB_l[a_i]) / 1000.0
          if service_level_capacity_TiB <= 100.0 and max(target_capacity_TiB,service_level_capacity_TiB) >= 4.0:
             if service_level_capacity_TiB > target_capacity_TiB:
                anf_capacity_TiB = service_level_capacity_TiB
             else:
                anf_capacity_TiB = target_capacity_TiB
             (capacity_TiB, write_bw_GBps, read_bw_GBps, write_iops, read_iops) = anf_perf_capacity(anf_capacity_TiB,  anf_MBps_per_TiB_l[a_i], anf_iops_per_TiB_l[a_i])
             anf_description = "ANF {} {:d} TiB".format(anf_service_level_l[a_i],int(anf_capacity_TiB))
             anf_d[anf_description] = {}
             anf_d[anf_description]['total_cost_per_month'] = anf_capacity_TiB * 730 * anf_per_GiB_per_hr_l[a_i] * 1024
             anf_d[anf_description]['capacity_TiB'] =  capacity_TiB
             anf_d[anf_description]['write_bw_GBps'] =  write_bw_GBps
             anf_d[anf_description]['read_bw_GBps'] =  read_bw_GBps
             anf_d[anf_description]['write_iops'] =  write_iops
             anf_d[anf_description]['read_iops'] =  read_iops

   count=0
   for key, value in sorted(anf_d.items(), key=lambda item: item[1]['total_cost_per_month']):
       if count < group_report_size and not pd.isna(anf_d[key]['total_cost_per_month']):
          all_d[key] = {}
          all_d[key]['total_cost_per_month'] = value['total_cost_per_month']
          all_d[key]['capacity_TiB'] = value['capacity_TiB']
          all_d[key]['write_bw_GBps'] = value['write_bw_GBps']
          all_d[key]['read_bw_GBps'] = value['read_bw_GBps']
          all_d[key]['write_iops'] = value['write_iops']
          all_d[key]['read_iops'] = value['read_iops']
          count = count + 1


def blob_storage(all_d, blob_tier_l,  blob_egress_Gbps_l, blob_cost_per_TiB_l, blob_ingress_Gbps_l, blob_read_cost_per_10k_ops_l,  blob_write_cost_per_10k_ops_l):

   blob_d = {}
   for b_i,tier in enumerate(blob_tier_l):
      if target_capacity_TiB > blob_storage_capacity_limit_TiB or target_performance_GBps > blob_egress_Gbps_l[b_i]/8.0:
         continue
      blob_description = "{} Blob {} TiB".format(tier,target_capacity_TiB)
      blob_d[blob_description] = {}
      blob_capacity_cost_per_month = target_capacity_TiB * blob_cost_per_TiB_l[b_i]
      blob_write_bw_MBps = blob_ingress_Gbps_l[b_i] * 1000.0 / 8.0
      blob_read_bw_MBps = blob_egress_Gbps_l[b_i] * 1000.0 / 8.0
      blob_write_operation_ps = blob_write_bw_MBps / blob_block_size_MiB
      blob_read_operation_ps = blob_read_bw_MBps / blob_block_size_MiB
      blob_write_10k_operation_per_month = (blob_write_operation_ps * 3600.0 * 24.0 * 30.0 * (1.0 - blob_read_percent)) / 10000.0
      blob_read_10k_operation_per_month = (blob_read_operation_ps * 3600.0 * 24.0 * 30.0 * blob_read_percent) / 10000.0
      blob_read_ops_cost_per_month = blob_read_10k_operation_per_month * blob_read_cost_per_10k_ops_l[b_i]
      blob_write_ops_cost_per_month = blob_write_10k_operation_per_month * blob_write_cost_per_10k_ops_l[b_i]
      blob_cost_per_month = blob_capacity_cost_per_month + blob_read_ops_cost_per_month + blob_write_ops_cost_per_month
      blob_d[blob_description]['total_cost_per_month'] = blob_cost_per_month
      blob_d[blob_description]['capacity_TiB'] =  target_capacity_TiB
      blob_d[blob_description]['write_bw_GBps'] =  blob_write_bw_MBps / 1000.0
      blob_d[blob_description]['read_bw_GBps'] =  blob_read_bw_MBps / 1000.0
      blob_d[blob_description]['write_iops'] =  "unknown"
      blob_d[blob_description]['read_iops'] =  "unknown"

   count=0
   for key, value in sorted(blob_d.items(), key=lambda item: item[1]['total_cost_per_month']):
       if count < group_report_size and not pd.isna(blob_d[key]['total_cost_per_month']):
          all_d[key] = {}
          all_d[key]['total_cost_per_month'] = value['total_cost_per_month']
          all_d[key]['capacity_TiB'] = value['capacity_TiB']
          all_d[key]['write_bw_GBps'] = value['write_bw_GBps']
          all_d[key]['read_bw_GBps'] = value['read_bw_GBps']
          all_d[key]['write_iops'] = value['write_iops']
          all_d[key]['read_iops'] = value['read_iops']
          count = count + 1      


def hpc_cache(all_d,hpc_cache_throughput_GBps_l,hpc_cache_capacity_small_TiB_l,hpc_cache_capacity_medium_TiB_l,hpc_cache_capacity_large_TiB_l,hpc_cache_cost_small_per_month_l,hpc_cache_cost_medium_per_month_l,hpc_cache_cost_large_per_month_l):
   if target_capacity_TiB > hpc_cache_max_capacity_TiB or target_performance_GBps > hpc_cache_max_throughput_GBps:
      return
   hpc_cache_d = {}
   for h_i, hpc_cache_throughput_GBps in enumerate(hpc_cache_throughput_GBps_l):
      if hpc_cache_throughput_GBps >= target_performance_GBps:
         hpc_cache_cost_l = [hpc_cache_cost_small_per_month_l[h_i],hpc_cache_cost_medium_per_month_l[h_i],hpc_cache_cost_large_per_month_l[h_i]]
         for hc_i, hpc_cache_capacity_TiB in enumerate([hpc_cache_capacity_small_TiB_l[h_i],hpc_cache_capacity_medium_TiB_l[h_i],hpc_cache_capacity_large_TiB_l[h_i]]):
            if hpc_cache_capacity_TiB >= target_capacity_TiB:
               hpc_cache_description = "HPC Cache {} GB/s {} TiB".format(hpc_cache_throughput_GBps,hpc_cache_capacity_TiB)
               hpc_cache_d[hpc_cache_description] = {}
               hpc_cache_d[hpc_cache_description]['total_cost_per_month'] = hpc_cache_cost_l[hc_i]
               hpc_cache_d[hpc_cache_description]['capacity_TiB'] =  hpc_cache_capacity_TiB
               hpc_cache_d[hpc_cache_description]['write_bw_GBps'] =  hpc_cache_throughput_GBps * hpc_cache_write_throughput_percent
               hpc_cache_d[hpc_cache_description]['read_bw_GBps'] =  hpc_cache_throughput_GBps
               hpc_cache_d[hpc_cache_description]['write_iops'] =  "unknown"
               hpc_cache_d[hpc_cache_description]['read_iops'] =  "unknown"
               break
         break 
   
   count=0
   for key, value in sorted(hpc_cache_d.items(), key=lambda item: item[1]['total_cost_per_month']):
       if count < group_report_size and not pd.isna(hpc_cache_d[key]['total_cost_per_month']):
          all_d[key] = {}
          all_d[key]['total_cost_per_month'] = value['total_cost_per_month']
          all_d[key]['capacity_TiB'] = value['capacity_TiB']
          all_d[key]['write_bw_GBps'] = value['write_bw_GBps']
          all_d[key]['read_bw_GBps'] = value['read_bw_GBps']
          all_d[key]['write_iops'] = value['write_iops']
          all_d[key]['read_iops'] = value['read_iops']
          count = count + 1      
           

def storage_report(all_d):

   print("")
   print("Azure Storage cost report (Target Performance = {} GB/s, Target Capacity = {} TiB)".format(target_performance_GBps, target_capacity_TiB))  
   print("")
   if detailed_report:
      print("{:^38} {:^14} {:^14} {:^14} {:^14} {:^14} {:^16}".format("Storage","Capacity_TiB","Read_BW_GB/s","Write_BW_GB/s","Read_IOPS","Write_IOPS","Cost/Month(PAYGO)"))
      print("{:=<38} {:=^14} {:=^14} {:=^14} {:=^14} {:=^14} {:=^16}".format("=","=","=","=","=","=","="))
      count=0
      for key, value in sorted(all_d.items(), key=lambda item: item[1]['total_cost_per_month']):
         if count < total_report_size and not pd.isna(all_d[key]['total_cost_per_month']):
            if isinstance(value['read_iops'], str):
               print("{:<38}  {:<14,.2f} {:<14,.2f} {:<14,.2f} {:<14} {:<14} ${:<16,.2f}".format(key,value['capacity_TiB'],value['read_bw_GBps'],value['write_bw_GBps'],value['read_iops'],value['write_iops'],value['total_cost_per_month']))
            else:   
               print("{:<38}  {:<14,.2f} {:<14,.2f} {:<14,.2f} {:<14,} {:<14,} ${:<16,.2f}".format(key,value['capacity_TiB'],value['read_bw_GBps'],value['write_bw_GBps'],int(value['read_iops']),int(value['write_iops']),value['total_cost_per_month']))
            count = count + 1
   else:
      print("{:^38} {:^16}".format("Storage","Cost/Month(PAYGO)"))
      print("{:=<38} {:=^16}".format("=","="))
      count=0
      for key, value in sorted(all_d.items(), key=lambda item: item[1]['total_cost_per_month']):
         if count < total_report_size and not pd.isna(all_d[key]['total_cost_per_month']):
            print("{:<38} ${:<16,.2f}".format(key,value['total_cost_per_month']))
            count = count + 1
   print("")


def main():

    global target_performance_GBps, target_capacity_TiB, total_report_size, group_report_size, blob_read_percent, blob_block_size_MiB, detailed_report

    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("target_performance_GBps", type=float, help="Target total aggregate I/O performance in GB/s [float]")
    parser.add_argument("target_capacity_TiB", type=float, help="Target total storage capacity in TiB [float]")
    parser.add_argument("-r", "--total_report_size", type=int, default=24, help="Total number of items/lines in the storage report [int]")
    parser.add_argument("-g", "--group_report_size", type=int, default=4, help="Total number of items/lines in each storage report group or type of storage [int]")
    parser.add_argument("-brp", "--blob_read_percent", type=float, default=0.6, help="The percentage of total Blob I/O done by read (Used in calculating Blob I/O operations transfer costs [float]")
    parser.add_argument("-bbs", "--blob_block_size_MiB", type=float, default=32.0, help="Blob block size used in calculation of blob transfer operations cost [float]")
    parser.add_argument("-dr", "--detailed_report", action="store_true" ,help="Print a detailed report [None]")
    args = parser.parse_args()
    target_performance_GBps = args.target_performance_GBps
    target_capacity_TiB = args.target_capacity_TiB
    if args.total_report_size:
       total_report_size = args.total_report_size
    if args.group_report_size:
       group_report_size = args.group_report_size
    if args.blob_read_percent:
       blob_read_percent = args.blob_read_percent
    if args.blob_block_size_MiB:
       blob_block_size_MiB = args.blob_block_size_MiB
    if args.detailed_report:
       detailed_report = True
    else:
       detailed_report = False

    all_d = {}
    (disk_name_l,disk_size_TiB_l,disk_price_per_month_l,disk_iops_l,disk_throughput_MBps_l,vm_name_l,vm_vcpu_l,vm_mem_GiB_l,vm_tmp_storage_GiB_l,vm_max_num_data_disks_l,vm_max_cached_tmp_storage_throughput_MBps_l,vm_max_tmp_storage_read_throughput_MBps_l,vm_max_tmp_storage_write_throughput_MBps_l,vm_max_tmp_storage_iops_l,vm_max_uncached_disk_throughput_MBps_l,vm_max_uncached_disk_iops_l,vm_network_bw_Mbps_l,vm_cost_per_month_l,anf_service_level_l,anf_per_GiB_per_hr_l,anf_MBps_per_TiB_l,anf_iops_per_TiB_l,blob_tier_l,blob_egress_Gbps_l,blob_ingress_Gbps_l,blob_cost_per_TiB_l,blob_write_cost_per_10k_ops_l,blob_read_cost_per_10k_ops_l,hpc_cache_throughput_GBps_l,hpc_cache_capacity_small_TiB_l,hpc_cache_capacity_medium_TiB_l,hpc_cache_capacity_large_TiB_l,hpc_cache_cost_small_per_month_l,hpc_cache_cost_medium_per_month_l,hpc_cache_cost_large_per_month_l) = read_excel(excel_file)
    pfs_disk(all_d, vm_name_l, vm_max_uncached_disk_throughput_MBps_l,disk_name_l,disk_throughput_MBps_l,vm_max_num_data_disks_l,disk_size_TiB_l,vm_cost_per_month_l,disk_price_per_month_l,disk_iops_l, vm_max_uncached_disk_iops_l)
    pfs_local_ssd(all_d, vm_name_l, vm_tmp_storage_GiB_l, vm_max_tmp_storage_read_throughput_MBps_l,vm_max_tmp_storage_write_throughput_MBps_l,vm_cost_per_month_l,vm_network_bw_Mbps_l,vm_max_tmp_storage_iops_l)
    anf(all_d, anf_service_level_l,anf_per_GiB_per_hr_l,anf_MBps_per_TiB_l,anf_iops_per_TiB_l)
    nfs_disk(all_d, vm_name_l, vm_max_uncached_disk_throughput_MBps_l,disk_name_l,disk_throughput_MBps_l,vm_max_num_data_disks_l,disk_size_TiB_l,vm_cost_per_month_l,disk_price_per_month_l,vm_network_bw_Mbps_l, disk_iops_l, vm_max_uncached_disk_iops_l)
    nfs_local_ssd(all_d, vm_name_l, vm_tmp_storage_GiB_l, vm_max_tmp_storage_read_throughput_MBps_l, vm_max_tmp_storage_write_throughput_MBps_l, vm_cost_per_month_l,vm_network_bw_Mbps_l, vm_max_tmp_storage_iops_l)
    blob_storage(all_d, blob_tier_l,  blob_egress_Gbps_l, blob_cost_per_TiB_l, blob_ingress_Gbps_l, blob_read_cost_per_10k_ops_l,  blob_write_cost_per_10k_ops_l)
    hpc_cache(all_d,hpc_cache_throughput_GBps_l,hpc_cache_capacity_small_TiB_l,hpc_cache_capacity_medium_TiB_l,hpc_cache_capacity_large_TiB_l,hpc_cache_cost_small_per_month_l,hpc_cache_cost_medium_per_month_l,hpc_cache_cost_large_per_month_l)
    storage_report(all_d)


if __name__ == "__main__":
    main()
