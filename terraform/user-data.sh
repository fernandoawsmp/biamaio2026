#!/bin/bash
# Registrar esta instancia no cluster ECS
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
