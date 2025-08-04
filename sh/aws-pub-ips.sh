#!/usr/bin/env bash
# aws-pub-ips.sh
# Inventory public IPv4 (and optional IPv6) addresses in the current AWS account.
# Usage examples:
#   ./aws-pub-ips.sh                       # scan every region
#   ./aws-pub-ips.sh -r us-east-1          # scan a single region
#   ./aws-pub-ips.sh --regions "us-east-1 ap-southeast-1"

set -euo pipefail

############### ARG PARSING ###############
REGIONS=""      # default: empty ⇒ discover all regions
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--regions)
      REGIONS="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [-r|--regions \"us-east-1 us-west-2\"]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"; exit 1 ;;
  esac
done
###########################################

############### DISCOVER REGIONS ##########
if [[ -z "$REGIONS" ]]; then
  REGIONS=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)
fi
echo "Scanning regions: $REGIONS"
###########################################

all_ipv4=()
all_ipv6=()

for region in $REGIONS; do
  echo -e "\n========== Region: $region =========="
  export AWS_DEFAULT_REGION=$region

  ### Elastic IPs ###########################################################
  eips=$(aws ec2 describe-addresses --query 'Addresses[*].PublicIp' --output text)
  [[ -n "$eips" ]] && echo -e "\n[EIP] $eips"
  all_ipv4+=($eips)

  ### Public EC2 instance IPs ##############################################
  ec2_ipv4=$(aws ec2 describe-instances \
      --query 'Reservations[*].Instances[*].PublicIpAddress' \
      --output text | grep -v ^None || true)
  [[ -n "$ec2_ipv4" ]] && echo -e "\n[EC2] $ec2_ipv4"
  all_ipv4+=($ec2_ipv4)

  # Optional IPv6 collection
  ec2_ipv6=$(aws ec2 describe-instances \
      --query 'Reservations[*].Instances[*].NetworkInterfaces[*].Ipv6Addresses[*].Ipv6Address' \
      --output text)
  [[ -n "$ec2_ipv6" ]] && all_ipv6+=($ec2_ipv6)

  ### NAT Gateway public IPs ###############################################
  natgw_ipv4=$(aws ec2 describe-nat-gateways \
      --query 'NatGateways[*].NatGatewayAddresses[*].PublicIp' \
      --output text | grep -v ^None || true)
  [[ -n "$natgw_ipv4" ]] && echo -e "\n[NAT GW] $natgw_ipv4"
  all_ipv4+=($natgw_ipv4)

  ### BYOIP pools ###########################################################
  byoipv4=$(aws ec2 describe-public-ipv4-pools \
      --query 'PublicIpv4Pools[*].PoolAddressRanges[*].AddressRange' \
      --output text)
  [[ -n "$byoipv4" ]] && echo -e "\n[BYOIP Pool CIDRs] $byoipv4"

  ### Global Accelerator ####################################################
  # GA is global; run once (only if first region looped)
  if [[ $region == ${REGIONS%% *} ]]; then
    ga_ipv4=$(aws globalaccelerator list-accelerators \
        --query 'Accelerators[*].IpSets[*].IpAddresses' --output text)
    [[ -n "$ga_ipv4" ]] && echo -e "\n[Global Accelerator] $ga_ipv4"
    all_ipv4+=($ga_ipv4)
  fi

  ### Lightsail #############################################################
  ls_ipv4=$(aws lightsail get-static-ips \
      --query 'staticIps[*].ipAddress' --output text 2>/dev/null || true)
  [[ -n "$ls_ipv4" ]] && echo -e "\n[Lightsail Static IPs] $ls_ipv4"
  all_ipv4+=($ls_ipv4)

  ### Internet-facing Load Balancers (resolve DNS) ##########################
  elb_dns=$(aws elbv2 describe-load-balancers \
      --query 'LoadBalancers[?Scheme==`internet-facing`].DNSName' \
      --output text)
  if [[ -n "$elb_dns" ]]; then
    echo -e "\n[ELB DNS → IPv4]"
    for dns in $elb_dns; do
      ips=$(dig +short "$dns" | tr '\n' ' ')
      echo "$dns => $ips"
      all_ipv4+=($ips)
    done
  fi

  ### Public RDS endpoints ##################################################
  rds_dns=$(aws rds describe-db-instances \
      --query 'DBInstances[?PubliclyAccessible==`true`].Endpoint.Address' \
      --output text)
  if [[ -n "$rds_dns" ]]; then
    echo -e "\n[RDS DNS → IPv4]"
    for dns in $rds_dns; do
      ips=$(dig +short "$dns" | tr '\n' ' ')
      echo "$dns => $ips"
      all_ipv4+=($ips)
    done
  fi
done  # region loop ends

########### Summary ##########################################################
echo -e "\n=========== SUMMARY ==========="
uniq_ipv4=$(printf "%s\n" "${all_ipv4[@]}" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
echo "Total unique IPv4 addresses: $(echo "$uniq_ipv4" | wc -l)"
echo -e "\nList:"
echo "$uniq_ipv4"

if [[ ${#all_ipv6[@]} -gt 0 ]]; then
  uniq_ipv6=$(printf "%s\n" "${all_ipv6[@]}" | sort -u)
  echo -e "\nTotal unique IPv6 addresses: $(echo "$uniq_ipv6" | wc -l)"
  echo -e "\nList:"
  echo "$uniq_ipv6"
fi

