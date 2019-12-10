import React from 'react';

import read_value from './util.js'

import azure_disks_icon from './azure-disks.svg';
import azure_netappfiles_icon from './azure-netappfiles.svg';
import azure_vmss_icon from './azure-vmss.svg';
import azure_vm_icon from './azure-vm.svg';
import azure_vnet_icon from './azure-vnet.svg';
import azure_cyclecloud_icon from './cyclecloud.png';

class AnfPoolView extends React.Component {
    render() {
        const pool = this.props.pool;
        const volumes = [];
        Object.keys(pool.volumes).forEach(volume_name => {
            volumes.push(
                <li key={volume_name} className="list-group-item">
                    <p className="card-text m-0 p-0">
                        <b>Volume:</b> {volume_name}
                    </p>
                    <p className="card-text m-0 p-0">
                        <b>Size:</b> {pool.volumes[volume_name].size}
                    </p>
                    <p className="card-text m-0 p-0">
                        <b>Mount:</b> {pool.volumes[volume_name].mount}
                    </p>
                </li>
            );
        });
        return (
            <div className="resource card m-1">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <img
                        src={azure_disks_icon}
                        alt=""
                        width="24"
                        height="24"
                    />
                    {this.props.pool_name}
                    <span className="badge badge-info">pool</span>
                </div>
                <div className="card-body">
                    <p className="card-text m-0 p-0">
                        <b>Type:</b> {pool.service_level}
                    </p>
                    <p className="card-text m-0 p-0">
                        <b>Size:</b> {pool.size} TB
            </p>
                    <ul className="list-group mt-3 d-flex">{volumes}</ul>
                </div>
            </div>
        );
    }
}

class AnfResourceView extends React.Component {
    render() {
        const config = this.props.config;
        const resource_name = this.props.resource_name;
        const pools = [];
        Object.keys(config.storage[resource_name].pools).forEach(pool_name => {
            const resource = this.props.config.storage[resource_name];
            const key = resource_name + "_" + pool_name;
            pools.push(
                <AnfPoolView
                    key={key}
                    pool_name={resource_name}
                    pool={resource.pools[pool_name]}
                />
            );
        });
        return (
            <div className="card m-1">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <img src={azure_netappfiles_icon} alt="" width="24" height="24" />
                    {resource_name}
                    <span className="badge badge-info">netappfiles</span>
                </div>
                <div className="card-body">
                    <div className="d-flex flex-wrap">{pools}</div>
                </div>
            </div>
        );
    }
}

class ResourceView extends React.Component {
    render() {
        const config = this.props.config;
        const resource_name = this.props.resource_name;
        const resource_type = read_value(
            config,
            "resources." + resource_name + ".type"
        );
        const resource_sku = read_value(
            config,
            "resources." + resource_name + ".vm_type"
        );
        const resource_image = read_value(
            config,
            "resources." + resource_name + ".image"
        );
        const tags = [];
        this.props.config.resources[resource_name].tags.forEach(tag => {
            const key = resource_name + "_" + tag;
            tags.push(
                <span key={key} className="badge badge-primary m-1">
                    {tag}
                </span>
            );
        });
        const nodes = [];
        if (resource_type === "vm") {
            nodes.push(
                <li key={resource_name} className="list-group-item">
                    {resource_name}
                </li>
            );
        } else if (resource_type === "vmss") {
            const instances = read_value(
                config,
                "resources." + resource_name + ".instances"
            );
            for (var i = 0; i < instances; i++) {
                const node_name = resource_name + "_" + i;
                nodes.push(
                    <li key={node_name} className="list-group-item">
                        {node_name}
                    </li>
                );
            }
        }
        return (
            <div className="resource card m-1">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <img src={resource_type === "vm" ? azure_vm_icon : azure_vmss_icon} alt="" width="24" height="24" />
                    {resource_name}
                    <span className="badge badge-info">{resource_type}</span>
                </div>
                <div className="card-body">
                    <p className="card-text m-0 p-0">
                        <b>SKU:</b> {resource_sku}
                    </p>
                    <p className="card-text m-0 p-0">
                        <b>Image:</b> {resource_image}
                    </p>
                    <p className="card-text m-0 p-0">
                        <b>Tags:</b> {tags}
                    </p>
                    <ul className="list-group mt-3 d-flex text-center">{nodes}</ul>
                </div>
            </div>
        );
    }
}

class SubnetView extends React.Component {
    render() {
        const subnet_name = this.props.subnet_name;
        const address_prefix = this.props.config.vnet.subnets[subnet_name];
        const resources = [];
        if ("storage" in this.props.config) {
            Object.keys(this.props.config.storage).forEach(resource_name => {
                const resource = this.props.config.storage[resource_name];
                if (resource.subnet === subnet_name) {
                    resources.push(
                        <AnfResourceView
                            key={resource_name}
                            resource_name={resource_name}
                            config={this.props.config}
                        />
                    );
                }
            });
        }
        Object.keys(this.props.config.resources).forEach(resource_name => {
            const resource = this.props.config.resources[resource_name];
            if (resource.subnet === subnet_name) {
                resources.push(
                    <ResourceView
                        key={resource_name}
                        resource_name={resource_name}
                        config={this.props.config}
                    />
                );
            }
            if (resource.type === "cluster") {
                resources.push(
                    <CycleClusterView
                        key={resource_name}
                        cluster_name={resource_name}
                        config={this.props.config}
                    />
                );
           }
        });

        return (
            <div className="card m-1">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <img
                        src={azure_vnet_icon}
                        alt=""
                        width="24"
                        height="24"
                    />
                    {subnet_name} [{address_prefix}]
            <span className="badge badge-info">subnet</span>
                </div>
                <div className="card-body">
                    <div className="d-flex flex-wrap">{resources}</div>
                </div>
            </div>
        );
    }
}

class AzurehpcVnetView extends React.Component {
    render() {
        const subnets = [];
        Object.keys(this.props.config.vnet.subnets).forEach(subnet_name => {
            subnets.push(
                <SubnetView
                    key={subnet_name}
                    subnet_name={subnet_name}
                    config={this.props.config}
                />
            );
        });

        return (
            <div className="card">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <img
                        src={azure_vnet_icon}
                        alt=""
                        width="24"
                        height="24"
                    />
                    {this.props.config.vnet.name} [{this.props.config.vnet.address_prefix}]
            <span className="badge badge-info">vnet</span>
                </div>
                <div className="card-body">
                    <div className="d-flex flex-wrap">{subnets}</div>
                </div>
            </div>
        );
    }
}

class CycleClusterView extends React.Component {
    render() {
        const config = this.props.config;
        const cluster = this.props.cluster_name;
        const nodes = [];
        Object.keys(this.props.config.resources[cluster]).forEach(node_name => {
            if (node_name !== "type") {
            nodes.push(
                <CycleNodeView
                    key={cluster}
                    cluster_name={cluster}
                    node_name={node_name}
                    config={this.props.config}
                />
            );
            }
        });
        return (
            <div className="card m-1">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <img src={azure_cyclecloud_icon} alt="" width="24" height="24" />
                    {cluster}
                    <span className="badge badge-info">CycleCloud</span>
                </div>
                <div className="card-body">
                    <div className="d-flex flex-wrap">{nodes}</div>
                </div>
            </div>
        );
    }
}

class CycleNodeView extends React.Component {
    render() {
        //const config = this.props.config;
        const cluster = this.props.cluster_name;
        const node = this.props.node_name;
        //const nodes = [];
        //Object.keys(config.resources[cluster]).forEach(node => {
        //    nodes.push(
        //        <li key={node} className="list-group-item">
        //            <p className="card-text m-0 p-0">
        //                <b>Node:</b> {node}
        //            </p>
        //            <p className="card-text m-0 p-0">
        //                <b>Size:</b> {config.resources[cluster][node].type}
        //            </p>
        //            <p className="card-text m-0 p-0">
        //                <b>Mount:</b> {config.resources[cluster].type}
        //            </p>
         //       </li>
         //   );
        //});
        return (
            <div className="resource card m-1">
                <div className="card-header d-flex justify-content-between align-items-center">
                    <img src={this.props.config.resources[cluster][node].type === "node" ? azure_vm_icon : azure_vmss_icon} alt="" width="24" height="24" />
                    {this.props.node_name}
                    <span className="badge badge-info">{this.props.config.resources[cluster][node].type === "node" ? "node" : "nodearray" }</span>
                </div>
                <div className="card-body">
                    <p className="card-text m-0 p-0">
                        <b>Type:</b> {this.props.config.resources[cluster][node].type} 
                    </p>
                    <p className="card-text m-0 p-0">
                        <b>Size:</b> 456 TB
            </p>
                    <ul className="list-group mt-3 d-flex">567</ul>
                </div>
            </div>
        );
    }
}


export default AzurehpcVnetView;
