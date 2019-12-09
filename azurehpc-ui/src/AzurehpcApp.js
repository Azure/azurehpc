import React from 'react';

import AzurehpcInstallView from './AzurehpcInstallView'
import AzurehpcVnetView from './AzurehpcVnetView'
import AzurehpcEditorView from './AzurehpcEditorView'

class AzurehpcApp extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            config: {
                location: "westeurope",
                resource_group: "hpcresourcegroup",
                install_from: "NOT-SET",
                admin_user: "hpcadmin",
                vnet: {
                    name: "hpc",
                    address_prefix: "10.2.0.0/16",
                    subnets: { "compute": "10.2.4.0/22" }
                },
                variables: {},
                storage: {},
                resources: {},
                install: []
            },
            page: "overview",
            showMenu: false
        };
        this.fileOpenRef = React.createRef();
        this.showMenu = this.showMenu.bind(this);
        this.addVMResource = this.addVMResource.bind(this);
        this.addVMSSResource = this.addVMSSResource.bind(this);
        this.addStorage = this.addStorage.bind(this);

        const params = new URL(document.location.href).searchParams;
        if (params && params.get("o")) {
            const me = this;
            const url = params.get("o");
            var xmlhttp = new XMLHttpRequest();
            xmlhttp.onreadystatechange = function () {
                if (this.readyState === 4 && this.status === 200) {
                    var newjson;
                    try {
                        newjson = JSON.parse(this.responseText);
                    } catch (e) {
                        return;
                    }
                    me.setState({ config: newjson });
                }
            };
            xmlhttp.open("GET", url, true);
            xmlhttp.send();
        }

    }

    onFileSelection(event) {
        var me = this;
        if (event.target !== null) {
            var fileReader = new FileReader();
            fileReader.onloadend = e => {
                var newjson;
                try {
                    newjson = JSON.parse(fileReader.result);
                } catch (e) {
                    return;
                }
                me.setState({ config: newjson });
            };
            fileReader.readAsText(event.target.files[0]);
        }
    }

    onOpenClick() {
        this.fileOpenRef.current.click();
    }

    onExportClick() {
      var json = JSON.stringify(this.state.config, null, 4);
      const a = document.createElement("a");
      const file = new Blob([json], { type: "application/json" });
      a.href = URL.createObjectURL(file);
      a.download = "azurehpc.json";
      a.click();
    }

    showMenu(event) {
      event.preventDefault();
     this.setState(prevState => ({
       showMenu: !prevState.showMenu
     }));
    }

    addVMResource() {
      this.setState(prevState => ({
        config: {
          ...prevState.config,      
            resources: {
              ...prevState.config.resources,
            "newnode": {
              "type" : "vm",
              "vm_type": "Standard_DS8_v3",
              "public_ip": true,
              "image": "my",
              "subnet": "compute",
              "tags": [
                "cndefault",
                "disable-selinux"
              ] }
            },
            vnet: {
            ...prevState.config.vnet,
              subnets: {
              ...prevState.config.vnet.subnets,
                "compute": "10.2.4.0/22"
              }
            }
        }
      }))
    }

    addVMSSResource() {
      this.setState(prevState => ({
        config: {
          ...prevState.config,      
            resources: {
              ...prevState.config.resources,
            "newvmss": {
              "type" : "vmss",
              "vm_type": "Standard_DS8_v3",
              "image": "my",
              "subnet": "compute",
              "tags": [
                "cndefault",
                "disable-selinux"
              ] }
            },
            vnet: {
            ...prevState.config.vnet,
              subnets: {
              ...prevState.config.vnet.subnets,
                "compute": "10.2.4.0/22"
              }
            }
        }
      }))
    }

    addStorage() {
      this.setState(prevState => ({
        config: {
          ...prevState.config,      
            storage: {
              ...prevState.config.storage,
                "hpcnetapp": {
                  "type": "anf",
                  "subnet": "netapp",
                  "pools": {
                    "anfpool": {
                      "size": 10,
                      "service_level": "Premium",
                        "volumes": {
                          "anfvol1": {
                            "size": 4,
                            "mount": "/data"
                          }
                        }
                      }
                    }
                  }
            },
            vnet: {
            ...prevState.config.vnet,
              subnets: {
              ...prevState.config.vnet.subnets,
                "netapp": "10.2.4.0/22"
              }
            }
        }
      }))
    }

    render() {
        var content;
        const active_button = "btn btn-dark my-2 my-sm-0 active";
        const inactive_button = "btn btn-dark my-2 my-sm-0";
        const view_icons = (
            <ul className="navbar-nav mr-auto">
                <li className="nav-item nav-link">
                    <button
                        className={
                            this.state.page === "overview" ? active_button : inactive_button
                        }
                        onClick={() => {this.setState({page: "overview"})} }
                    >
                        <i className="fa fa-cloud"></i> Overview
                    </button>
                </li>
                <li className="nav-item nav-link">
                    <button
                        className={
                            this.state.page === "code" ? active_button : inactive_button
                        }
                        onClick={() => {this.setState({page: "code"})} }
                    >
                        <i className="fa fa-code"></i> Code
                    </button>
                </li>
                <li className="nav-item nav-link">
                    <button
                        className={
                            this.state.page === "install" ? active_button : inactive_button
                        }
                        onClick={() => {this.setState({page: "install"})} }
                    >
                        <i className="fa fa-reorder"></i> Install Steps
                    </button>
                </li>
                <li className="nav-item nav-link">
                    <button className={active_button} data-toggle="dropdown" onClick={this.showMenu}>
                    <i className="fa fa-reorder"></i> Add component
                    </button>
                </li>
          { this.state.showMenu ? (
              <div className="nav-item nav-link">
                <button className={inactive_button} onClick={this.addVMResource} > <i className="fa fa-reorder"> </i> VM </button>
                <button className={inactive_button} onClick={this.addVMSSResource} > <i className="fa fa-reorder"> </i> VMSS </button>
                <button className={inactive_button} onClick={this.addStorage} > <i className="fa fa-reorder"> </i> Storage </button>
              </div> ) : (null) }
            </ul>
        );
        if (this.state.page === "overview") {
            content = <AzurehpcVnetView config={this.state.config} />;
        } else if (this.state.page === "code") {
            content = <AzurehpcEditorView code={JSON.stringify(this.state.config, null, 4)} app={this} />;
        } else if (this.state.page === "install") {
            content = <AzurehpcInstallView config={this.state.config} />;
        }

        return (
            <div>
                <nav className="navbar navbar-expand-md navbar-dark bg-dark fixed-top">
                    <a className="navbar-brand" href="#top">azurehpc</a>
                    <button
                        className="navbar-toggler"
                        type="button"
                        data-toggle="collapse"
                        data-target="#navbarsExampleDefault"
                        aria-controls="navbarsExampleDefault"
                        aria-expanded="false"
                        aria-label="Toggle navigation"
                    >
                        <span className="navbar-toggler-icon" />
                    </button>

                    <div className="collapse navbar-collapse" id="navbarsExampleDefault">
                        {view_icons}
                        <div className="form-inline my-2 my-lg-0">
                            <button
                                className="btn btn-sm btn-success my-2 my-sm-0"
                                onClick={this.onOpenClick.bind(this)}
                            >
                                <i className="fa fa-folder-open"></i> Open
                            </button>
                            <input
                                ref={this.fileOpenRef}
                                type="file"
                                accept=".json"
                                onChange={this.onFileSelection.bind(this)}
                                hidden
                            />
                            &nbsp;
                            <button
                                className="btn btn-sm btn-success my-2 my-sm-0"
                                onClick={() => this.onExportClick(this.state.config)}
                            >
                                <i className="fa fa-folder-export"></i> Export
                            </button>
                        </div>
                    </div>
                </nav>
                <main className="container-fluid app-content min-100">
                    {content}
                </main>
            </div>
        );
    }
}

export default AzurehpcApp;
