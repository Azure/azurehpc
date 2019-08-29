import React from 'react';

class AzurehpcInstallView extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            selected: {
                type: "none"
            }
        };
    }

    updateSelection(selectedType, selectedItem) {
        if (
            this.state.selected &&
            selectedType === this.state.selected.type &&
            selectedItem === this.state.selected.item
        ) {
            this.setState({ selected: { type: "none" } });
        } else {
            this.setState({ selected: { type: selectedType, item: selectedItem } });
        }
    }

    render() {
        const config = this.props.config;
        const sel = this.state.selected;
        const install_steps = [];
        const sudo = <span className="badge badge-danger">sudo</span>;
        const selected_item =
            "list-group-item list-group-item-action flex-column align-items-start active";
        const unselected_item =
            "list-group-item list-group-item-action flex-column align-items-start";

        config.install.forEach((step, idx) => {
            const tag = <span className="badge badge-primary">{step.tag}</span>;
            const args = [];
            if ("args" in step && step.args.length > 0) {
                step.args.forEach((arg, argIdx) => {
                    args.push(
                        <span
                            key={"installstep-" + idx + "-arg-" + argIdx}
                            className="badge badge-secondary m-1"
                        >
                            {arg}
                        </span>
                    );
                });
            }
            const copy = [];
            if ("copy" in step && step.copy.length > 0) {
                step.copy.forEach((file, fileIdx) => {
                    copy.push(
                        <span
                            key={"installstep-" + idx + "-copy-" + fileIdx}
                            className="badge badge-secondary m-1"
                        >
                            {file}
                        </span>
                    );
                });
            }
            var selected = false;
            if (sel) {
                if (sel.type === "install") {
                    selected = sel.item === idx;
                } else if (
                    sel.type === "resource" &&
                    sel.item in config.resources &&
                    "tags" in config.resources[sel.item]
                ) {
                    selected = config.resources[sel.item].tags.includes(step.tag);
                }
            }
            install_steps.push(
                <li
                    key={"installstep" + idx}
                    className={selected ? selected_item : unselected_item}
                    onClick={() => this.updateSelection("install", idx)}
                >
                    <div className="mb-1 d-flex w-100 justify-content-between">
                        <div>
                            {step.script} {step.sudo ? sudo : ""}
                        </div>
                        <div>{tag}</div>
                    </div>
                    {args.length > 0 ? <p className="mb-1">Args: {args}</p> : ""}
                    {copy.length > 0 ? <p className="mb-1">Copy: {copy}</p> : ""}
                </li>
            );
        });

        const resources = [];

        Object.keys(config.resources).forEach(resource_name => {
            const resource = config.resources[resource_name];
            const res_tags = [];
            if ("tags" in resource) {
                resource.tags.forEach(tag => {
                    res_tags.push(
                        <span
                            key={resource_name + "-" + tag}
                            className="badge badge-primary m-1"
                        >
                            {tag}
                        </span>
                    );
                });
            }
            var selected = false;
            if (sel) {
                if (sel.type === "resource") {
                    selected = sel.item === resource_name;
                } else if (sel.type === "install" && sel.item < config.install.length) {
                    selected = config.resources[resource_name].tags.includes(
                        config.install[sel.item].tag
                    );
                }
            }
            resources.push(
                <li
                    key={"resource-" + resource_name}
                    className={selected ? selected_item : unselected_item}
                    onClick={() => this.updateSelection("resource", resource_name)}
                >
                    <div className="mb-1 d-flex w-100 justify-content-between">
                        <div>{resource_name}</div>
                        <div align="right">{res_tags}</div>
                    </div>
                </li>
            );
        });

        return (
            <div className="d-flex">
                <div className="mr-3">
                    <h3>Install Steps</h3>
                    <ul className="list-group">{install_steps}</ul>
                </div>
                <div>
                    <h3>Resources</h3>
                    <ul className="list-group">{resources}</ul>
                </div>
            </div>
        );
    }
}

export default AzurehpcInstallView;