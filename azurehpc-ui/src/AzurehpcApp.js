import React from 'react';

import AzurehpcInstallView from './AzurehpcInstallView'
import AzurehpcVnetView from './AzurehpcVnetView'
import AzurehpcEditorView from './AzurehpcEditorView'

class AzurehpcApp extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            config: {
                location: "NOT-SET",
                resource_group: "NOT-SET",
                install_from: "NOT-SET",
                admin_user: "NOT-SET",
                vnet: {
                    name: "NOT-SET",
                    address_prefix: "NOT-SET",
                    subnets: {}
                },
                variables: {},
                storage: {},
                resources: {},
                install: []
            },
            page: "overview"
        };
        this.fileOpenRef = React.createRef();

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
                            this.state.page === "install" ? active_button : inactive_button
                        }
                        onClick={() => {this.setState({page: "install"})} }
                    >
                        <i className="fa fa-reorder"></i> Install Steps
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
            </ul>
        );
        if (this.state.page === "overview") {
            content = <AzurehpcVnetView config={this.state.config} />;
        } else if (this.state.page === "install") {
            content = <AzurehpcInstallView config={this.state.config} />;
        } else if (this.state.page === "code") {
            content = <AzurehpcEditorView code={JSON.stringify(this.state.config, null, 4)} />;
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
