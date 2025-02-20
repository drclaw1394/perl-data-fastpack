console.log(msgpack);
console.log(fastpack);


{
  console.log("JSON object/map");
  let obj={hello:"there"};
  let fp_encode=fastpack.encode_meta_payload(obj, 0);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode, 0);

  console.log("Input",obj);
  console.log("Output",fp_decode);
}

{

  console.log("JSON array");
  let obj=[1,2,3];
  let fp_encode=fastpack.encode_meta_payload(obj, 0);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode,0);
  console.log("Input",obj);
  console.log("Output",fp_decode);
}

{
  console.log("Message pack object/map");
  let obj={hello:"there"};
  let fp_encode=fastpack.encode_meta_payload(obj, 1);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode, 0);
  console.log("Input",obj);
  console.log("Output",fp_decode);
}
{
  console.log("Message pack array");
  let obj=[1,2,3];
  let fp_encode=fastpack.encode_meta_payload(obj, 1);
  console.log(fp_encode);
  let fp_decode=fastpack.decode_meta_payload(fp_encode, 0);
  console.log("Input",obj);
  console.log("Output",fp_decode);
}



//
{
  let input=new Float64Array(1);
  input[0]=123232;
  let args={buffer:undefined, inputs:[{time:0 , id: 1, payload: new Uint8Array(input.buffer)}]};
  let e=fastpack.encode_message(args);
  let d=fastpack.decode_message(args);
  console.log("input:",args);
  console.log("output:", args);
}


{
  console.log("Encoding Namespace");
  let input=new Float64Array(1);
  input[0]=123;//65535;
  let e_ns=fastpack.create_namespace();

  let args={buffer:undefined, inputs:[{time:0 , id: "testtest", payload: new Uint8Array(input.buffer)}],ns:e_ns};
  let e=fastpack.encode_message(args);
  console.log("Encoded byte length", e);
  console.log(args.buffer);


  console.log("Decoding Namespace");
  let outputs=[];
  let d_ns=fastpack.create_namespace();
  let d_args={buffer:args.buffer, outputs:outputs, ns:d_ns};
  let d=fastpack.decode_message(d_args);
  console.log("input:",args);
  console.log("output:", d_args);

  let buffer=d_args.outputs[0].payload.buffer;
  console.log("output array buffer is", buffer);

  let view=new DataView(buffer); 
  console.log("Float value output", view.getFloat64(0,1));


  //Remove ns entry
  console.log("REMOVE ENTRY");
  args={buffer:undefined, inputs:[{time:0 , id: "testtest", payload: new Uint8Array(0)}],ns:e_ns};
  e=fastpack.encode_message(args);
  console.log("input:",args);

  outputs=[];
  d_args={buffer:args.buffer, outputs:outputs, ns:d_ns};
  d=fastpack.decode_message(d_args);
  console.log("output:",d_args);
}



