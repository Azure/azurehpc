import React from 'react';
import Editor from "@monaco-editor/react"
import ReactResizeDetector from 'react-resize-detector';
import Popup from './Popup';

class AzurehpcEditorView extends React.Component {
    editor = null;

    constructor(props){  
      super(props);  
      this.state = { showPopup: false };  
    }  

    togglePopup() {  
      this.setState({  
        showPopup: !this.state.showPopup  
      });  
    }  

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
          //this.togglePopup()
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
        return (
          <ReactResizeDetector
            handleWidth
            handleHeight
            onResize={() => {
                if (this.editor) {
                    //this.editor.layout();
                }
            }}
          >
            <button onClick={this.listenEditorChanges.bind(this)} key="savekey"> Save Code </button>

          {this.state.showPopup ?  
            <Popup  
                text='Click "Close Button" to hide popup'  
                closePopup={this.togglePopup.bind(this)}  
            />  
          : null  
          }  

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
