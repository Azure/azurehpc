import React from 'react';
import Editor from "@monaco-editor/react"
import ReactResizeDetector from 'react-resize-detector';

class AzurehpcEditorView extends React.Component {
    editor = null;

    editorDidMount = (editor) => {
        this.editor = editor;
        //editor.focus();
    };

    render() {
        const code = this.props.code;
        const options = {
            selectOnLineNumbers: true,
            readOnly: true
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