import React from 'react';
import Editor from "@monaco-editor/react"
import ReactResizeDetector from 'react-resize-detector';

class AzurehpcEditorView extends React.Component {
    editor = null;

    editorDidMount = (_, editor) => {
        console.log('Didmount');
        this.editor = editor;
        //editor.focus();
    }

    listenEditorChanges() {
        //console.log(this.editor.getValue());
        try {
        JSON.parse(this.editor.getValue());
        } catch (e) {
        return false;
        }
        this.props.app.setState({config: JSON.parse(this.editor.getValue())});
    }

    render() {
        const code = this.props.code;
        const options = {
            selectOnLineNumbers: true,
            readOnly: false
        };
        return (<ReactResizeDetector
            handleWidth
            handleHeight
            onResize={() => {
                if (this.editor) {
                    //this.editor.layout();
                }
            }}
        >
            <button onClick={this.listenEditorChanges.bind(this)} key="savekey">
                  Save Code 
            </button>
            <Editor
                language="json"
                theme="vs"
                value={code}
                options={options}
                editorDidMount={this.editorDidMount}
            />
        </ReactResizeDetector>
        );
    }
}

export default AzurehpcEditorView;
